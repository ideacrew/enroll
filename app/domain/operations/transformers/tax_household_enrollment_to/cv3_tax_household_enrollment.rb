# frozen_string_literal: true

require 'dry/monads'
require 'dry/monads/do'

module Operations
  module Transformers
    module TaxHouseholdEnrollmentTo
      # TaxHouseholdEnrollment params to be transformed.
      class Cv3TaxHouseholdEnrollment
        include Dry::Monads[:do, :result]

        def call(tax_household_enrollment)
          request_payload = yield construct_payload(tax_household_enrollment)

          Success(request_payload)
        end

        private

        def tax_household_reference_hash(th_enr)
          @tax_household = th_enr.tax_household
          {
            hbx_id: @tax_household.hbx_assigned_id.to_s,
            max_aptc: money_to_currency(@tax_household.max_aptc),
            yearly_expected_contribution: money_to_currency(@tax_household.yearly_expected_contribution)
          }
        end

        def hbx_enrollment_reference_hash(th_enr)
          @enrollment = th_enr.enrollment
          {
            hbx_id: @enrollment.hbx_id,
            effective_on: @enrollment.effective_on,
            aasm_state: @enrollment.aasm_state,
            is_active: @enrollment.is_active,
            market_place_kind: @enrollment.kind,
            enrollment_period_kind: @enrollment.enrollment_kind,
            product_kind: @enrollment.coverage_kind
          }
        end

        def tax_household_members_enrollment_members_hash(th_enr)
          th_enr.tax_household_members_enrollment_members.collect do |member|
            hbx_enr_member = @enrollment.hbx_enrollment_members.where(id: member.hbx_enrollment_member_id).first
            fm_reference = fetch_family_member_reference(hbx_enr_member)
            {
              hbx_enrollment_member: fetch_hbx_enrollment_member(fm_reference, hbx_enr_member),
              tax_household_member: fetch_tax_household_member(fm_reference, member),
              age_on_effective_date: member.age_on_effective_date,
              family_member_reference: fm_reference,
              relationship_with_primary: member.relationship_with_primary,
              date_of_birth: member.date_of_birth
            }
          end
        end

        def fetch_tax_household_member(fm_reference, member)
          thh_member = @tax_household.tax_household_members.where(id: member.tax_household_member_id).first
          return {} if thh_member.blank?

          {
            family_member_reference: fm_reference,
            product_eligibility_determination: fetch_product_eligibility_determination(thh_member),
            is_subscriber: thh_member.is_subscriber
          }
        end

        def fetch_product_eligibility_determination(member)
          {
            is_ia_eligible: member.is_ia_eligible,
            is_medicaid_chip_eligible: member.is_medicaid_chip_eligible,
            is_non_magi_medicaid_eligible: member.is_non_magi_medicaid_eligible,
            is_totally_ineligible: member.is_totally_ineligible,
            is_without_assistance: member.is_without_assistance,
            magi_medicaid_monthly_household_income: member.magi_medicaid_monthly_household_income&.to_hash,
            medicaid_household_size: member.medicaid_household_size,
            magi_medicaid_monthly_income_limit: member.magi_medicaid_monthly_income_limit&.to_hash,
            magi_as_percentage_of_fpl: member.magi_as_percentage_of_fpl,
            magi_medicaid_category: member.magi_medicaid_category,
            csr: member.csr_eligibility_kind.split('_').last
          }
        end

        def fetch_hbx_enrollment_member(fm_reference, hbx_enr_member)
          return {} if hbx_enr_member.blank?

          {
            family_member_reference: fm_reference,
            is_subscriber: hbx_enr_member.is_subscriber,
            eligibility_date: hbx_enr_member.eligibility_date,
            coverage_start_on: hbx_enr_member.coverage_start_on
          }
        end

        def fetch_family_member_reference(hbx_enr_member)
          return {} if hbx_enr_member.blank?

          {
            family_member_hbx_id: hbx_enr_member.hbx_id, age: hbx_enr_member.age_on_effective_date,
            first_name: hbx_enr_member.person.first_name, last_name: hbx_enr_member.person.last_name,
            person_hbx_id: hbx_enr_member.person.hbx_id, is_primary_family_member: (hbx_enr_member.primary_relationship == 'self')
          }
        end

        def construct_payload(th_enr)
          payload = { tax_household_reference: tax_household_reference_hash(th_enr),
              hbx_enrollment_reference: hbx_enrollment_reference_hash(th_enr),
              health_product_hios_id: th_enr.health_product_hios_id,
              dental_product_hios_id: th_enr.dental_product_hios_id,
              household_benchmark_ehb_premium: money_to_currency(th_enr.household_benchmark_ehb_premium),
              household_health_benchmark_ehb_premium: money_to_currency(th_enr.household_health_benchmark_ehb_premium),
              household_dental_benchmark_ehb_premium: money_to_currency(th_enr.household_dental_benchmark_ehb_premium),
              applied_aptc: money_to_currency(th_enr.applied_aptc),
              available_max_aptc: money_to_currency(th_enr.available_max_aptc),
              tax_household_members_enrollment_members: tax_household_members_enrollment_members_hash(th_enr) }
          Success(payload)
        rescue StandardError => e
          Failure("Cv3TaxHouseholdEnrollment transform failure for enrollment hbx id: #{th_enr&.enrollment&.hbx_id} | exception: #{e.inspect} | backtrace: #{e.backtrace.inspect}")
        end

        def money_to_currency(value)
          (value || Money.new(0)).to_hash
        end
      end
    end
  end
end
