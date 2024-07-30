# frozen_string_literal: true

require 'dry/monads'
require 'dry/monads/do'

module Operations
  module PremiumCredits
    # This operation is to find Max Aptc
    class FindAptcWithTaxHouseholds
      include Dry::Monads[:do, :result]
      include FloatHelper

      def call(params)
        values = yield validate(params)
        result = yield find_max_available_aptc(values)

        Success(result)
      end

      private

      def validate(params)
        return Failure('Invalid params. hbx_enrollment should be an instance of Hbx Enrollment') unless params[:hbx_enrollment].is_a?(HbxEnrollment)
        return Failure('Missing effective_on') unless params[:effective_on]
        return Failure('Missing tax households') unless params[:tax_households]

        Success(params)
      end

      def find_max_available_aptc(values)
        @hbx_enrollment = values[:hbx_enrollment]
        @effective_on = values[:effective_on]
        @exclude_enrollments_list = values[:exclude_enrollments_list] || []
        @family = @hbx_enrollment.family
        @tax_households = values[:tax_households]
        @include_term_enrollments = values[:include_term_enrollments]
        @is_migrating = values[:is_migrating]

        return Success(0.0) if not_eligible?

        Success(available_aptc)
      end

      def not_eligible?
        return true if @hbx_enrollment.dental?

        @current_tax_households = @tax_households.select {|th| th.tax_household_members.any? { |thm| enrolled_family_member_ids.include?(thm.applicant_id.to_s) } }
        return true if @current_tax_households.blank?

        false
      end

      def available_aptc
        @current_tax_households.reduce(0.0) do |sum, current_tax_household|
          expected_contribution = monthly_expected_contribution(current_tax_household)
          total_benchmark_premium = current_benchmark_premium(current_tax_household) + coinciding_benchmark_premium(current_tax_household)

          value = (total_benchmark_premium - expected_contribution - utilized_aptc(current_tax_household)).round

          persist_tax_household_enrollment(current_tax_household, value)

          sum += (value < 0) ? 0.0 : value
          sum
        end
      end

      def coinciding_benchmark_premium(current_tax_household)
        th_enrollments = TaxHouseholdEnrollment.where(:enrollment_id.in => coinciding_enrollments.map(&:id), tax_household_id: current_tax_household.id)
        round_down_float_two_decimals(th_enrollments.sum(&:household_benchmark_ehb_premium))
      end

      def current_benchmark_premium(current_tax_household)
        return 0.0 if benchmark_premiums.blank?
        round_down_float_two_decimals(benchmark_premiums.households.find {|household| household.household_id.to_s == current_tax_household.id.to_s }&.household_benchmark_ehb_premium || 0.0)
      end

      def persist_tax_household_enrollment(current_tax_household, available_max_aptc)
        th_enrollment = TaxHouseholdEnrollment.where(enrollment_id: @hbx_enrollment.id, tax_household_id: current_tax_household.id).first

        if th_enrollment.present?
          return if @is_migrating
        else
          th_enrollment = TaxHouseholdEnrollment.create(enrollment_id: @hbx_enrollment.id, tax_household_id: current_tax_household.id)
        end

        household_info = benchmark_premiums.households.find {|household| household.household_id.to_s == current_tax_household.id.to_s } if benchmark_premiums.present?

        th_enrollment.update!(
          household_benchmark_ehb_premium: (household_info&.household_benchmark_ehb_premium || 0.0),
          health_product_hios_id: household_info&.health_product_hios_id,
          dental_product_hios_id: household_info&.dental_product_hios_id,
          household_health_benchmark_ehb_premium: household_info&.household_health_benchmark_ehb_premium,
          household_dental_benchmark_ehb_premium: household_info&.household_dental_benchmark_ehb_premium,
          available_max_aptc: available_max_aptc
        )

        return if household_info.blank?

        persist_tax_household_members_enrollment_members(current_tax_household, th_enrollment, household_info)
      end

      def persist_tax_household_members_enrollment_members(current_tax_household, th_enrollment, household_info)
        th_id = BSON::ObjectId.from_string(current_tax_household.id.to_s)
        tax_household_group = @family.tax_household_groups.order_by(created_at: :desc).where(:"tax_households._id" => th_id).first
        tax_household = tax_household_group.tax_households.where(_id: th_id).first
        hbx_enrollment_members = @hbx_enrollment.hbx_enrollment_members
        tax_household_members = tax_household.tax_household_members
        th_member_ids = current_tax_household.tax_household_members.where(is_ia_eligible: true).map(&:applicant_id).map(&:to_s)

        (th_member_ids & enrolled_family_member_ids).each do |family_member_id|
          hbx_enrollment_member_id = hbx_enrollment_members.where(applicant_id: family_member_id).first&.id
          tax_household_member_id = tax_household_members.where(applicant_id: family_member_id).first&.id
          member_info = household_info.members.find {|member| member[:family_member_id].to_s == family_member_id.to_s }

          next if member_info.blank?

          th_member_enr_member = th_enrollment.tax_household_members_enrollment_members.find_or_create_by(
            family_member_id: family_member_id
          )

          th_member_enr_member.update!(
            hbx_enrollment_member_id: hbx_enrollment_member_id&.to_s,
            tax_household_member_id: tax_household_member_id&.to_s,
            age_on_effective_date: member_info.age_on_effective_date,
            relationship_with_primary: member_info.relationship_with_primary,
            date_of_birth: member_info.date_of_birth
          )
        end
      end

      def utilized_aptc(current_tax_household)
        coinciding_enrollments.reduce(0.0) do |sum, previous_enrollment|
          th_enrollment = TaxHouseholdEnrollment.where(enrollment_id: previous_enrollment.id, tax_household_id: current_tax_household.id).first
          next sum if th_enrollment.blank?
          value = round_down_float_two_decimals(th_enrollment.available_max_aptc)

          sum += (value > 0.0 ? value : 0.0)
          sum
        end
      end

      def default_applied_aptc_percentage
        EnrollRegistry[:aca_individual_assistance_benefits].setting(:default_applied_aptc_percentage).item
      end

      def monthly_expected_contribution(current_tax_household)
        grant_value = round_down_float_two_decimals(current_tax_household.yearly_expected_contribution) # value is string.
        (grant_value / 12)
      end

      def coinciding_enrollments
        return @coinciding_enrollments if defined? @coinciding_enrollments

        @hbx_enrollment.generate_hbx_signature

        is_primary_enrolling = is_primary_enrolling?(@hbx_enrollment)

        @coinciding_enrollments = target_enrollments.reject do |previous_enrollment|
          previous_enrollment.generate_hbx_signature

          @exclude_enrollments_list.include?(previous_enrollment.hbx_id) ||
            !previous_enrollment.product.can_use_aptc? ||
            (previous_enrollment.enrollment_signature == @hbx_enrollment.enrollment_signature) ||
            (is_primary_enrolling && primary_reenrolling?(previous_enrollment))
        end
      end

      def primary_reenrolling?(previous_enrollment)
        return false unless is_primary_enrolling?(previous_enrollment)
        true
      end

      def is_primary_enrolling?(enrollment)
        enrollment.hbx_enrollment_members.map { |member| member.applicant_id.to_s }.include?(@family.primary_applicant.id.to_s)
      end

      def enrolled_family_member_ids
        @hbx_enrollment.hbx_enrollment_members.map(&:applicant_id).map(&:to_s)
      end

      def target_enrollments
        @target_enrollments ||= if @include_term_enrollments
                                  enrollments
                                else
                                  enrollments.enrolled
                                end
      end

      def enrollments
        @family.active_household.hbx_enrollments.show_enrollments_sans_canceled.individual_market.where(:effective_on => {:"$gte" => @effective_on.beginning_of_year, :"$lte" => @effective_on.end_of_year})
      end

      def coinciding_family_members
        return @coinciding_family_members if defined? @coinciding_family_members
        @coinciding_family_members = coinciding_enrollments.map(&:hbx_enrollment_members).flatten.map(&:applicant_id).map(&:to_s).uniq
      end

      def benchmark_premiums
        return @benchmark_premiums if defined? @benchmark_premiums

        households_hash = @current_tax_households.inject([]) do |result, current_tax_household|
          members_hash = (current_tax_household.tax_household_members.where(is_ia_eligible: true).map(&:applicant_id).map(&:to_s) & enrolled_family_member_ids).inject([]) do |member_result, member_id|
            next member_result if coinciding_family_members.include? member_id
            family_member = FamilyMember.find(member_id)

            member_result << {
              family_member_id: member_id,
              coverage_start_on: @hbx_enrollment.hbx_enrollment_members.where(applicant_id: member_id).first&.coverage_start_on,
              relationship_with_primary: family_member.primary_relationship
            }

            member_result
          end

          next result if members_hash.blank?

          result << {
            household_id: current_tax_household.id.to_s,
            members: members_hash
          }
          result
        end

        return nil if households_hash.blank?

        payload = {
          family_id: @family.id,
          effective_date: @effective_on,
          households: households_hash,
          is_migrating: @is_migrating,
          hbx_enrollment: @hbx_enrollment
        }

        result = ::Operations::BenchmarkProducts::IdentifySlcspWithPediatricDentalCosts.new.call(payload)

        raise "IdentifySlcspWithPediatricDentalCosts raised an error - #{result.failure}" unless result.success?

        @benchmark_premiums = result.value!
      end
    end
  end
end
