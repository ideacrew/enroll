# frozen_string_literal: true

require 'dry/monads'
require 'dry/monads/do'

module Operations
  module PremiumCredits
    # This operation is to find Max Aptc
    class FindAptc
      include Dry::Monads[:result, :do]
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

        Success(params)
      end

      def find_max_available_aptc(values)
        @hbx_enrollment = values[:hbx_enrollment]
        @effective_on = values[:effective_on]
        @family = @hbx_enrollment.family

        return Success(0.0) if not_eligible?

        Success(available_aptc.round)
      end

      def not_eligible?
        return true if @hbx_enrollment.dental?

        result = ::Operations::PremiumCredits::FindAll.new.call({ family: @hbx_enrollment.family, year: @effective_on.year, kind: 'AdvancePremiumAdjustmentGrant' })
        return true if result.failure?

        @aptc_grants = result.value!
        @current_enrolled_aptc_grants = @aptc_grants.where(:member_ids.in => enrolled_family_member_ids)
        return true if @current_enrolled_aptc_grants.blank?

        false
      end

      def available_aptc
        @current_enrolled_aptc_grants.reduce(0.0) do |sum, aptc_grant|
          expected_contribution = monthly_expected_contribution(aptc_grant)
          total_benchmark_premium = current_benchmark_premium(aptc_grant) + coinciding_benchmark_premium(aptc_grant)

          value = total_benchmark_premium - expected_contribution - utilized_aptc(aptc_grant)

          persist_tax_household_enrollment(aptc_grant, value)

          sum += (value < 0) ? 0.0 : value
          sum
        end
      end

      def coinciding_benchmark_premium(aptc_grant)
        th_enrollments = TaxHouseholdEnrollment.where(:enrollment_id.in => coinciding_enrollments.map(&:id), tax_household_id: aptc_grant.tax_household_id)
        round_down_float_two_decimals(th_enrollments.sum(&:household_benchmark_ehb_premium))
      end

      def current_benchmark_premium(aptc_grant)
        round_down_float_two_decimals(benchmark_premiums.households.find {|household| household.household_id == aptc_grant.tax_household_id }&.household_benchmark_ehb_premium || 0.0)
      end

      def persist_tax_household_enrollment(aptc_grant, available_max_aptc)
        th_enrollment = TaxHouseholdEnrollment.find_or_create_by(enrollment_id: @hbx_enrollment.id, tax_household_id: aptc_grant.tax_household_id)
        household_info = benchmark_premiums.households.find {|household| household.household_id == aptc_grant.tax_household_id }

        th_enrollment.update!(
          household_benchmark_ehb_premium: (household_info&.household_benchmark_ehb_premium || 0.0),
          health_product_hios_id: household_info&.health_product_hios_id,
          dental_product_hios_id: household_info&.dental_product_hios_id,
          household_health_benchmark_ehb_premium: household_info&.household_health_benchmark_ehb_premium,
          household_dental_benchmark_ehb_premium: household_info&.household_dental_benchmark_ehb_premium,
          available_max_aptc: available_max_aptc
        )

        persist_tax_household_members_enrollment_members(aptc_grant, th_enrollment, household_info)
      end

      def persist_tax_household_members_enrollment_members(aptc_grant, th_enrollment, household_info)
        return if household_info.blank?
        tax_household_group = @family.tax_household_groups.order_by(created_at: :desc).first
        tax_household = tax_household_group.tax_households.where(id: aptc_grant.tax_household_id).first
        hbx_enrollment_members = @hbx_enrollment.hbx_enrollment_members
        tax_household_members = tax_household.tax_household_members

        (aptc_grant.member_ids & @hbx_enrollment.hbx_enrollment_members.map(&:applicant_id).map(&:to_s)).each do |family_member_id|
          hbx_enrollment_member_id = hbx_enrollment_members.where(applicant_id: family_member_id).first&.id
          tax_household_member_id = tax_household_members.where(applicant_id: family_member_id).first&.id
          member_info = household_info.members.find {|member| member[:family_member_id].to_s == family_member_id.to_s }

          th_member_enr_member = th_enrollment.tax_household_members_enrollment_members.find_or_create_by(
            hbx_enrollment_member_id: hbx_enrollment_member_id&.to_s,
            tax_household_member_id: tax_household_member_id&.to_s
          )

          th_member_enr_member.update!(
            family_member_id: family_member_id,
            age_on_effective_date: member_info.age_on_effective_date,
            relationship_with_primary: member_info.relationship_with_primary,
            date_of_birth: member_info.date_of_birth
          )
        end
      end

      def utilized_aptc(aptc_grant)
        coinciding_enrollments.reduce(0.0) do |sum, previous_enrollment|
          pct = previous_enrollment.elected_aptc_pct > 0.0 ? previous_enrollment.elected_aptc_pct : default_applied_aptc_percentage
          th_enrollment = TaxHouseholdEnrollment.where(enrollment_id: previous_enrollment.id, tax_household_id: aptc_grant.tax_household_id).first
          next sum if th_enrollment.blank?
          # value = (round_down_float_two_decimals(th_enrollment.total_benchmark_premium) - (round_down_float_two_decimals(aptc_grant.value) / 12)) * pct
          value = round_down_float_two_decimals(th_enrollment.available_max_aptc) * pct

          sum += (value > 0.0 ? value : 0.0)
          sum
        end

        # round_down_float_two_decimals(coinciding_enrollments.sum(&:applied_aptc_amount))
      end

      def default_applied_aptc_percentage
        EnrollRegistry[:aca_individual_assistance_benefits].setting(:default_applied_aptc_percentage).item
      end

      def monthly_expected_contribution(aptc_grant)
        grant_value = round_down_float_two_decimals(aptc_grant.value) # value is string.
        (grant_value / 12)
      end

      def total_monthly_benchmark_premium(aptc_grant)
        benchmark_premiums.households.find {|household| household.household_id == aptc_grant.tax_household_id }.household_benchmark_ehb_premium
      end

      def coinciding_enrollments
        return @coinciding_enrollments if defined? @coinciding_enrollments

        @hbx_enrollment.generate_hbx_signature

        is_primary_enrolling = is_primary_enrolling?(@hbx_enrollment)

        @coinciding_enrollments = active_enrollments.reject do |previous_enrollment|
          previous_enrollment.generate_hbx_signature

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

      def active_enrollments
        @active_enrollments ||= @family.active_household.hbx_enrollments.enrolled.individual_market
      end

      def coinciding_family_members
        return @coinciding_family_members if defined? @coinciding_family_members
        @coinciding_family_members = coinciding_enrollments.map(&:hbx_enrollment_members).map(&:to_s).uniq
      end

      def benchmark_premiums
        return @benchmark_premiums if defined? @benchmark_premiums

        households_hash = @current_enrolled_aptc_grants.inject([]) do |result, aptc_grant|
          members_hash = (aptc_grant.member_ids & enrolled_family_member_ids).inject([]) do |member_result, member_id|
            next member_result if coinciding_family_members.include? member_id
            family_member = FamilyMember.find(member_id)

            member_result << {
              family_member_id: member_id,
              relationship_with_primary: family_member.primary_relationship
            }

            member_result
          end

          next result if members_hash.blank?

          result << {
            household_id: aptc_grant.tax_household_id.to_s,
            members: members_hash
          }
          result
        end

        payload = {
          family_id: @family.id,
          effective_date: @effective_on,
          households: households_hash
        }

        result = ::Operations::BenchmarkProducts::IdentifySlcspWithPediatricDentalCosts.new.call(payload)

        raise "IdentifySlcspWithPediatricDentalCosts raised an error - #{result.failure}" unless result.success?

        @benchmark_premiums = result.value!
      end
    end
  end
end
