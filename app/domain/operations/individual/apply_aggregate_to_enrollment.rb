# frozen_string_literal: true

require 'dry/monads'
require 'dry/monads/do'

module Operations
  module Individual
    # Create new enrollment to apply available aggregate enrollment for an existing enrollment.
    class ApplyAggregateToEnrollment
      include Dry::Monads[:result, :do]
      include FloatHelper
      def call(params)
        validated_eligibility   = yield validate(params)
        eligible_enrollments    = yield fetch_enrollments_to_renew(validated_eligibility)
        generate_enrollments    = yield generate_enrollments(eligible_enrollments, params[:eligibility_determination])
        Success(generate_enrollments)
      end

      private

      def validate(params)
        return Failure("Given object is not a valid eligibility determination object") unless params[:eligibility_determination].is_a?(EligibilityDetermination)
        return Failure("No active tax household for given eligibility") unless params[:eligibility_determination].tax_household.present?
        Success(params[:eligibility_determination])
      end

      def fetch_enrollments_to_renew(eligibility_determination)
        effective_year = eligibility_determination.tax_household.effective_starting_on.year
        enrollments = eligibility_determination.family.active_household.hbx_enrollments.enrolled_and_renewal.individual_market.by_health.by_year(effective_year)
        return Failure('Cannot find any IVL health enrollments in any of the active states.') if enrollments.blank?
        enrollment_list = enrollments.reject do |enr|
          next if enr.product.blank?
          enr.product.metal_level_kind == :catastrophic
        end
        enrollment_list.present? ? Success(enrollment_list) : Failure('Cannot find any enrollments with Non-Catastrophic Plan.')
      end

      def generate_enrollments(enrollments, eligibility_determination)
        latest_tax_household = eligibility_determination.tax_household
        enrollments.each do |enrollment|
          date = Insured::Factories::SelfServiceFactory.find_enrollment_effective_on_date(TimeKeeper.date_of_record.in_time_zone('Eastern Time (US & Canada)'), enrollment.effective_on).to_date
          max_aptc = latest_tax_household.monthly_max_aptc(enrollment, date)
          applied_percentage = applied_aptc_pct_for(enrollment, date)
          applied_aptc = float_fix(max_aptc * applied_percentage)
          attrs = {enrollment_id: enrollment.id, elected_aptc_pct: applied_percentage, aptc_applied_total: applied_aptc}
          ::Insured::Forms::SelfTermOrCancelForm.for_aptc_update_post(attrs)
        end
        Success("Aggregate amount applied on to enrollments")
      end

      def applied_aptc_pct_for(enrollment, new_effective_date)
        subscriber = enrollment.subscriber || enrollment.hbx_enrollment_members.first

        if osse_aptc_minimum_enabled? && subscriber.role_for_subsidy.osse_eligible?(new_effective_date)
          return enrollment.elected_aptc_pct if enrollment.elected_aptc_pct >= minimum_applied_aptc_for_osse.to_f
          minimum_applied_aptc_for_osse
        else
          enrollment.elected_aptc_pct > 0 ? enrollment.elected_aptc_pct : default_applied_aptc
        end
      end

      def osse_aptc_minimum_enabled?
        EnrollRegistry.feature_enabled?(:aca_individual_osse_aptc_minimum)
      end

      def default_applied_aptc
        EnrollRegistry[:aca_individual_assistance_benefits].setting(:default_applied_aptc_percentage).item
      end

      def minimum_applied_aptc_for_osse
        EnrollRegistry[:aca_individual_assistance_benefits].setting(:minimum_applied_aptc_percentage_for_osse).item
      end
    end
  end
end
