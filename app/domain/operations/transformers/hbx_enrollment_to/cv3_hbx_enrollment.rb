# frozen_string_literal: true

require 'dry/monads'
require 'dry/monads/do'
require 'aca_entities/magi_medicaid/libraries/iap_library'

module Operations
  module Transformers
    module HbxEnrollmentTo
      # Person params to be transformed.
      class Cv3HbxEnrollment

        include Dry::Monads[:do, :result]
        include Acapi::Notifiers
        require 'securerandom'

        # !!!Important!!!
        # options param is a temporary solution and currently accepts attribute (exclude_seps)in cv3_hbx_enrollment - developed for Pivotal-184575110,
        # **Do not pass in options(exclude_seps) elsewhere unless approved from Dan/leadership team**
        # !!!Important!!!
        def call(enrollment, options = {})
          @transformed_th_enrs = yield transform_enr_tax_households(enrollment)
          request_payload = yield construct_payload(enrollment, options)

          Success(request_payload)
        end

        private

        # rubocop:disable Metrics/CyclomaticComplexity, Metrics/AbcSize
        def construct_payload(enr, options)
          product = enr.product
          issuer = product&.issuer_profile
          consumer_role = enr&.consumer_role
          payload = {
            hbx_id: enr.hbx_id,
            effective_on: enr.effective_on,
            aasm_state: enr.aasm_state,
            market_place_kind: enr.kind,
            enrollment_period_kind: enr.enrollment_kind,
            terminated_on: enr.terminated_on,
            product_kind: enr.coverage_kind,
            total_premium: enr.total_premium,
            applied_aptc_amount: { cents: enr.applied_aptc_amount.cents, currency_iso: enr.applied_aptc_amount.currency.iso_code },
            hbx_enrollment_members: enrollment_member_hash(enr)
          }
          payload.merge!(is_receiving_assistance: (enr.applied_aptc_amount > 0 || (product.is_csr? ? true : false))) if product
          payload.merge!(consumer_role_reference: consumer_role_reference(consumer_role)) if consumer_role
          if product && issuer
            family_rated_info = family_tier_total_premium(product, enr)
            payload.merge!(product_reference: product_reference(product, issuer, family_rated_info))
          end
          payload.merge!(issuer_profile_reference: issuer_profile_reference(issuer)) if issuer
          payload.merge!(special_enrollment_period_reference: special_enrollment_period_reference(enr)) if enr.is_special_enrollment? && !options[:exclude_seps]
          payload.merge!(tax_households_references: @transformed_th_enrs) if @transformed_th_enrs.present?
          Success(payload)
        rescue StandardError => e
          Failure("Cv3HbxEnrollment hbx id: #{enr&.hbx_id} | exception: #{e.inspect} | backtrace: #{e.backtrace.inspect}")
        end
        # rubocop:enable Metrics/CyclomaticComplexity, Metrics/AbcSize

        def tax_household_enrollments(enr)
          TaxHouseholdEnrollment.where(enrollment_id: enr.id)
        end

        def transform_enr_tax_households(enrollment)
          th_enrs = tax_household_enrollments(enrollment)
          return Success([]) unless th_enrs.present?

          transformed_th_enrs = th_enrs.map do |tax_household_enr|
            transform_tax_household_enr(tax_household_enr)
          end
          return Failure("Could not transform tax household enrollment(s): #{transformed_th_enrs.select(&:failure?).map(&:failure)}") unless transformed_th_enrs.all?(&:success?)

          Success(transformed_th_enrs.map(&:value!))
        end

        def transform_tax_household_enr(tax_household_enr)
          Operations::Transformers::TaxHouseholdEnrollmentTo::Cv3TaxHouseholdEnrollment.new.call(tax_household_enr)
        end

        def fetch_special_enrollment_period(enrollment)
          family = enrollment.family

          seps = family.special_enrollment_periods.select do |sep|
            (sep.start_on..sep.end_on).cover?(enrollment.submitted_at) if sep.start_on.present? && sep.end_on.present?
          end

          seps.max_by(&:created_at)
        end

        def special_enrollment_period_reference(enrollment)
          sep = enrollment.special_enrollment_period || fetch_special_enrollment_period(enrollment)
          return {} unless sep.present?

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

        def pediatric_dental_ehb(product)
          return 0.0 if product.health?

          product.ehb_apportionment_for_pediatric_dental
        end

        def family_tier_total_premium(product, enr)
          return {} if product.blank? || product.health? || product.age_based_rating?

          qhp = ::Products::Qhp.where(standard_component_id: product.hios_base_id, active_year: product.active_year).first
          exchange_provided_code = enr.rating_area&.exchange_provided_code
          return {} if exchange_provided_code.blank?

          qhp_table = qhp.qhp_premium_tables.where(rate_area_id: enr.rating_area.exchange_provided_code).first
          return {} if qhp_table.blank?

          {
            exchange_provided_code: exchange_provided_code,
            primary_enrollee: qhp_table.primary_enrollee,
            primary_enrollee_one_dependent: qhp_table.primary_enrollee_one_dependent,
            primary_enrollee_two_dependents: qhp_table.primary_enrollee_two_dependent,
            primary_enrollee_many_dependent: qhp_table.primary_enrollee_many_dependent
          }
        end

        def product_reference(product, issuer, family_rated_info)
          {
            hios_id: product.hios_id,
            name: product.title,
            active_year: product.active_year,
            is_dental_only: product.dental?,
            metal_level: product.metal_level_kind.to_s,
            benefit_market_kind: product.benefit_market_kind.to_s,
            csr_variant_id: product.csr_variant_id,
            is_csr: product.is_csr?,
            family_deductible: product.family_deductible,
            individual_deductible: product.deductible,
            product_kind: product.product_kind.to_s,
            rating_method: product.rating_method,
            pediatric_dental_ehb: pediatric_dental_ehb(product),
            family_rated_premiums: family_rated_info,
            issuer_profile_reference: { hbx_id: issuer.hbx_id, name: issuer.legal_name, abbrev: issuer.abbrev }
          }
        end

        def fetch_slcsp_benchmark_premium_for_member(person_hbx_id, slcsp_info)
          return if slcsp_info.blank?

          slcsp_info.dig(person_hbx_id, :health_only_slcsp_premiums, :cost)&.to_money&.to_hash
        end

        def fetch_slcsp_info(family, effective_date)
          premiums = ::Operations::Products::Fetch.new.call({ family: family, effective_date: effective_date })
          return {} if premiums.failure?

          slcsp_info = ::Operations::Products::FetchSlcsp.new.call(member_silver_product_premiums: premiums.success)
          return {} if slcsp_info.failure?
          slcsp_info.success
        end

        # Include SlCSP Member Premium for all HbxEnrollmentMembers
        def enrollment_member_hash(enrollment)
          slcsp_info = fetch_slcsp_info(enrollment.family, enrollment.effective_on)

          enrollment.hbx_enrollment_members.collect do |hem|
            person = hem.person

            member_hash = {
              family_member_reference: {
                family_member_hbx_id: hem.hbx_id,
                age: hem.age_on_effective_date,
                first_name: person.first_name,
                last_name: person.last_name,
                person_hbx_id: person.hbx_id,
                is_primary_family_member: (hem.primary_relationship == 'self')
              },
              is_subscriber: hem.is_subscriber,
              eligibility_date: hem.eligibility_date,
              coverage_start_on: hem.coverage_start_on,
              coverage_end_on: hem.coverage_end_on,
              tobacco_use: hem.tobacco_use,
              slcsp_member_premium: fetch_slcsp_benchmark_premium_for_member(person.hbx_id, slcsp_info)
            }

            member_hash.merge!(non_tobacco_use_premium: enrollment.premium_for_non_tobacco_use(hem).to_money.to_hash) if hem.tobacco_use == "Y"
            member_hash
          end
        end
      end
    end
  end
end
