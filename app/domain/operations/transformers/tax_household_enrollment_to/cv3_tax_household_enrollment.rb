# frozen_string_literal: true

require 'dry/monads'
require 'dry/monads/do'

module Operations
  module Transformers
    module TaxHouseholdEnrollmentTo
      # TaxHouseholdEnrollment params to be transformed.
      class Cv3TaxHouseholdEnrollment
        include Dry::Monads[:result, :do]

        def call(tax_household_enrollment)
          request_payload = yield construct_payload(tax_household_enrollment)

          Success(request_payload)
        end

        private

        def tax_household_reference_hash(th_enr)
          tax_household = th_enr.tax_household
          {
            hbx_id: tax_household.hbx_id,
            max_aptc: tax_household.max_aptc,
            yearly_expected_contribution: tax_household.yearly_expected_contribution
          }
        end

        def hbx_enrollment_reference_hash(th_enr)
          enrollment = th_enr.enrollment
          {
            hbx_id: enrollment.hbx_id,
            effective_on: enrollment.effective_on,
            aasm_state: enrollment.aasm_state,
            is_active: enrollment.is_active,
            market_place_kind: enrollment.market_place_kind,
            enrollment_period_kind: enrollment.enrollment_period_kind,
            product_kind: enrollment.product_kind
          }
        end

        def tax_household_members_enrollment_members_hash(th_enr)
          th_enr.tax_household_members_enrollment_members.collect do |member|
            {
              hbx_enrollment_member_id: member.hbx_enrollment_member_id,
              tax_household_member_id: member.tax_household_member_id,
              age_on_effective_date: member.age_on_effective_date,
              family_member_id: member.family_member_id,
              relationship_with_primary: member.relationship_with_primary,
              date_of_birth: member.date_of_birth
            }
          end
        end

        def construct_payload(th_enr)
          {
            tax_household_reference: tax_household_reference_hash(th_enr),
            hbx_enrollment_reference: hbx_enrollment_reference_hash(th_enr),
            health_product_hios_id: th_enr.health_product_hios_id,
            dental_product_hios_id: th_enr.dental_product_hios_id,
            household_benchmark_ehb_premium: th_enr.household_benchmark_ehb_premium,
            household_health_benchmark_ehb_premium: th_enr.household_health_benchmark_ehb_premium,
            household_dental_benchmark_ehb_premium: th_enr.household_dental_benchmark_ehb_premium,
            applied_aptc: th_enr.applied_aptc,
            available_max_aptc: th_enr.available_max_aptc,
            tax_household_members_enrollment_members: tax_household_members_enrollment_members_hash(th_enr)
          }
        end
      end
    end
  end
end
