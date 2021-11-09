# frozen_string_literal: true

require 'dry/monads'
require 'dry/monads/do'
require 'aca_entities/magi_medicaid/libraries/iap_library'

module Operations
  module Transformers
    module HbxEnrollmentTo
      # Person params to be transformed.
      class Cv3HbxEnrollment

        include Dry::Monads[:result, :do]
        include Acapi::Notifiers
        require 'securerandom'

        def call(enrollment)
          request_payload = yield construct_payload(enrollment)

          Success(request_payload)
        end

        private

        # rubocop:disable Metrics/CyclomaticComplexity
        def construct_payload(enr)
          product = enr.product
          issuer = product&.issuer_profile
          consumer_role = enr&.consumer_role
          payload = {
            effective_on: enr.effective_on,
            aasm_state: enr.aasm_state,
            market_place_kind: enr.kind,
            enrollment_period_kind: enr.enrollment_kind,
            product_kind: enr.coverage_kind,
            total_premium: enr.total_premium,
            applied_aptc_amount: { cents: enr.applied_aptc_amount.cents, currency_iso: enr.applied_aptc_amount.currency.iso_code },
            hbx_enrollment_members: enrollment_member_hash(enr)
          }
          payload.merge!(is_receiving_assistance: (enr.applied_aptc_amount > 0 || (product.is_csr? ? true : false))) if product
          payload.merge!(consumer_role_reference: consumer_role_reference(consumer_role)) if consumer_role
          payload.merge!(product_reference: product_reference(product, issuer)) if product && issuer
          payload.merge!(issuer_profile_reference: issuer_profile_reference(issuer)) if issuer
          payload.merge!(special_enrollment_period_reference: special_enrollment_period_reference(enr)) if enr.is_special_enrollment? && enr.family.latest_active_sep

          Success(payload)
        end
        # rubocop:enable Metrics/CyclomaticComplexity

        def special_enrollment_period_reference(enrollment)
          sep = enrollment.family.latest_active_sep
          qle = sep.qualifying_life_event_kind
          {
            qualifying_life_event_kind_reference: construct_qle_reference(sep.qualifying_life_event_kind),
            qle_on: sep.qle_on,
            start_on: sep.start_on,
            end_on: sep.end_on,
            effective_on: sep.effective_on,
            submitted_at: sep.submitted_at
          }
        end

        def construct_qle_reference(qle)
          return if qle.nil?

          qle_hash = {
            start_on: qle.start_on,
            title: qle.title,
            reason: qle.reason,
            market_kind: qle.market_kind
          }
          qle_hash.merge!(end_on: qle.end_on) if qle.end_on.present?
          qle_hash
        end

        def consumer_role_reference(consumer_role)
          {
            is_active: consumer_role.is_active,
            is_applying_coverage: consumer_role.is_applying_coverage,
            is_applicant: consumer_role.is_applicant,
            is_state_resident: consumer_role.is_state_resident || false,
            lawful_presence_determination: {},
            citizen_status: consumer_role.citizen_status
          }
        end

        def issuer_profile_reference(issuer)
          {
            hbx_id: issuer.hbx_id,
            name: issuer.legal_name,
            abbrev: issuer.abbrev || issuer.legal_name,
            phone: issuer.office_locations.where(is_primary: true).first&.phone&.full_phone_number
          }
        end

        def product_reference(product, issuer)
          {
            hios_id: product.hios_id,
            name: product.title,
            active_year: product.active_year,
            is_dental_only: product.dental?,
            metal_level: product.metal_level,
            benefit_market_kind: product.benefit_market_kind.to_s,
            csr_variant_id: product.csr_variant_id,
            is_csr: product.is_csr?,
            family_deductible: product.family_deductible,
            individual_deductible: product.deductible,
            product_kind: product.product_kind.to_s,
            issuer_profile_reference: { hbx_id: issuer.hbx_id, name: issuer.legal_name, abbrev: issuer.abbrev }
          }
        end

        def enrollment_member_hash(enrollment)
          enrollment.hbx_enrollment_members.collect do |hem|
            person = hem.person
            {
              family_member_reference: {family_member_hbx_id: hem.hbx_id, age: hem.age_on_effective_date, first_name: person.first_name, last_name: person.last_name, person_hbx_id: person.hbx_id,
                                        is_primary_family_member: (hem.primary_relationship == 'self')}, is_subscriber: hem.is_subscriber, eligibility_date: hem.eligibility_date, coverage_start_on: hem.coverage_start_on
            }
          end
        end
      end
    end
  end
end
