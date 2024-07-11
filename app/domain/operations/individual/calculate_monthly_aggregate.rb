# frozen_string_literal: true

require 'dry/monads'
require 'dry/monads/do'

module Operations
  module Individual
    # Calculate Yearly Aggregate amount based on current enrollment
    class CalculateMonthlyAggregate
      include Dry::Monads[:do, :result]
      include FloatHelper

      def call(params)
        values               = yield validate(params)
        amount_consumed      = yield consumed_aptc_amount(values)
        calculated_aggregate = yield calculate_monthly_aggregate(amount_consumed)

        Success(calculated_aggregate)
      end

      private

      def validate(params)
        return Failure('Given object is not a valid family object.') unless params[:family].is_a?(Family)
        return Failure('Given effective_on not a valid Date object.') unless params[:effective_on].is_a?(Date)
        return Failure('Shopping Enrollment Family Member Ids are not present.') if params[:shopping_fm_ids].blank?
        return Failure('Subscriber Applicant Id is missing.') if params[:subscriber_applicant_id].blank?

        Success(params)
      end

      def consumed_aptc_amount(values)
        @effective_on = values[:effective_on]
        @family = values[:family]
        @shopping_fm_ids = values[:shopping_fm_ids]
        @subscriber_applicant_id = values[:subscriber_applicant_id]

        aptc_enrollments = HbxEnrollment.yearly_aggregate(@family.id, @effective_on.year)
        aptc_enrollments = aptc_enrollments.reject{|enr| enr.effective_on >= @effective_on && enr.subscriber.applicant_id == @subscriber_applicant_id}
        consumed_aptc = 0
        aptc_enrollments.each do |enrollment|
          consumed_aptc += aptc_amount_consumed_by_enrollment(enrollment)
        end
        Success(consumed_aptc)
      end

      def aptc_amount_consumed_by_enrollment(enrollment)
        termination_date = calculate_termination_date(enrollment)
        @old_enr_effective_on = enrollment.effective_on
        @applied_aptc = enrollment.applied_aptc_amount.to_f
        first_month_aptc = aptc_consumed_in_effective_month(termination_date)
        full_months_aptc = aptc_consumed_in_full_months(termination_date)
        last_month_aptc  = aptc_consumed_in_terminated_month(termination_date)
        first_month_aptc + full_months_aptc + last_month_aptc
      end

      def aptc_consumed_in_effective_month(termination_date)
        total_days = @old_enr_effective_on.end_of_month.day
        no_of_days_aptc_consumed =
          if @old_enr_effective_on == @old_enr_effective_on.beginning_of_month
            if termination_date <= @old_enr_effective_on
              0
            elsif termination_date.month != @old_enr_effective_on.month
              total_days
            elsif termination_date.month == @old_enr_effective_on.month
              termination_date.day - (@old_enr_effective_on.day - 1)
            end
          else
            total_days - (@old_enr_effective_on.day - 1)
          end
        no_of_days_aptc_consumed.fdiv(total_days) * @applied_aptc
      end

      def aptc_consumed_in_full_months(termination_date)
        if (termination_date.month - 1) <= @old_enr_effective_on.month
          0
        else
          (termination_date.month - 1) - @old_enr_effective_on.month
        end * @applied_aptc
      end

      def aptc_consumed_in_terminated_month(termination_date)
        total_days = termination_date.end_of_month.day
        if @old_enr_effective_on.month == termination_date.month || termination_date < @old_enr_effective_on
          0
        else
          termination_date.day.fdiv(total_days) * @applied_aptc
        end
      end

      def calculate_termination_date(enrollment)
        calculated_term_date = new_temination_date(enrollment)
        return enrollment.terminated_on if enrollment.coverage_terminated? && enrollment.terminated_on < calculated_term_date
        calculated_term_date
      end

      def new_temination_date(enrollment)
        if enrollment.subscriber.applicant_id.to_s == @subscriber_applicant_id.to_s
          end_date = EnrollRegistry[:calculate_monthly_aggregate].settings(:termination_date).item
          end_date == :end_of_month ? @effective_on - 1.day : enrollment.effective_on.end_of_year
        else
          enrollment.effective_on.end_of_year
        end
      end

      def active_eligible_coverage_months
        eligible_enrollments = @family.hbx_enrollments.eligible_covered_aggregate(@family.id, @effective_on.year).reject{|enr| enr.product.metal_level_kind == :catastrophic}
        counter = (1..(@effective_on.month - 1)).inject(0) do |countr, month|
          countr += 1 if eligible_enrollments.any?{ |enr| (enr.effective_on.beginning_of_month..calculate_termination_date(enr)).cover?(Date.new(@effective_on.year, month)) }
          countr
        end
        if @effective_on.day != 1 && eligible_enrollments.any?{ |enr| (enr.effective_on.beginning_of_month..calculate_termination_date(enr)).cover?(Date.new(@effective_on.year, @effective_on.month)) }
          counter += round_down_float_two_decimals((@effective_on.day - 1) / @effective_on.end_of_month.day.to_f)
        end
        counter
      end

      #logic to calculate the monthly Aggregate
      def calculate_monthly_aggregate(consumed_aptc)
        latest_max_aptc = @family.active_household.latest_active_tax_household_with_year(@effective_on.year)&.latest_eligibility_determination&.max_aptc&.to_f
        return Success(0.00) unless latest_max_aptc
        eligile_month_setting = EnrollRegistry[:calculate_monthly_aggregate].settings(:eligible_months).item
        eligible_months = eligile_month_setting ? (pct_of_effective_month + number_of_remaining_full_months + active_eligible_coverage_months) : 12
        available_annual_aggregate = (latest_max_aptc * eligible_months) - consumed_aptc.to_f
        monthly_max = calculated_new_monthly_aggregate(available_annual_aggregate)
        Success(monthly_max)
      end

      def calculated_new_monthly_aggregate(available_annual_aggregate)
        total_no_of_months = pct_of_effective_month + number_of_remaining_full_months
        round_down_float_two_decimals(available_annual_aggregate / total_no_of_months)
      end

      def pct_of_effective_month
        total_days = @effective_on.end_of_month.day
        (total_days - (@effective_on.day - 1)) / total_days.to_f
      end

      def number_of_remaining_full_months
        12 - @effective_on.month
      end
    end
  end
end
