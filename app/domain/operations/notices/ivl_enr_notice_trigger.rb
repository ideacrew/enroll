# frozen_string_literal: true

require 'dry/monads'
require 'dry/monads/do'

module Operations
  module Notices
    # IVL enrollment notice
    class IvlEnrNoticeTrigger
      include Dry::Monads[:result, :do]
      include EventSource::Command
      include EventSource::Logging

      def call(params)
        values = yield validate(params)
        family = yield fetch_family(values[:enrollment])
        fm_hash = yield build_family_member_hash(family)
        household_hash = yield build_household_hash(family, values[:enrollment].effective_on.year)
        payload = yield build_payload(fm_hash, household_hash)
        validated_payload = yield validate_payload(payload)
        event = yield build_event(validated_payload)
        result = yield publish_response(event)

        Success(result)
      end

      private

      def validate(params)
        return Failure('Missing Enrollment') if params[:enrollment].blank?

        Success(params)
      end

      def fetch_family(enrollment)
        Success(enrollment.family)
      end

      def build_family_member_hash(family)
        family_member_hash = family.family_members.collect do |fm|
          person = fm.person
          outstanding_verification_types = person.consumer_role.outstanding_verification_types
          {
            is_primary_applicant: fm.is_primary_applicant,
            person: {
              hbx_id: person.hbx_id,
              person_name: { first_name: person.first_name, last_name: person.last_name },
              person_demographics: { ssn: person.ssn, gender: person.gender, dob: person.dob, is_incarcerated: person.is_incarcerated },
              person_health: { is_tobacco_user: person.is_tobacco_user },
              is_active: person.is_active,
              is_disabled: person.is_disabled,
              verification_types: outstanding_verification_types.collect {|vt| {type_name: vt.type_name, validation_status: vt.validation_status, due_date: vt.due_date}}
            }
          }
        end
        Success(family_member_hash)
      end

      def build_household_hash(family, year)
        household_hash = family.households.collect do |household|
          enrollments = household.hbx_enrollments.enrolled.with_product.by_year(year)
          {
            start_date: household.effective_starting_on,
            is_active: household.is_active,
            irs_group_reference: {},
            coverage_households: household.coverage_households.collect { |ch| {is_immediate_family: ch.is_immediate_family, coverage_household_members: ch.coverage_household_members.collect {|chm| {is_subscriber: chm.is_subscriber}}} },
            hbx_enrollments: build_enrollments_hash(enrollments)
          }
        end
        Success(household_hash)
      end

      def build_enrollments_hash(enrollments)
        enrollments.collect do |enr|
          product = enr.product
          issuer = product.issuer_profile
          consumer_role = enr.consumer_role
          {
            effective_on: enr.effective_on,
            aasm_state: enr.aasm_state,
            market_place_kind: enr.kind,
            enrollment_period_kind: enr.enrollment_kind,
            product_kind: enr.coverage_kind,
            hbx_enrollment_members: enr.hbx_enrollment_members.collect do |hem|
                                      {family_member_reference: {family_member_hbx_id: hem.hbx_id}, is_subscriber: hem.is_subscriber, eligibility_date: hem.eligibility_date, coverage_start_on: hem.coverage_start_on}
                                    end,
            product_reference: {hios_id: product.hios_id, name: product.title, active_year: product.active_year, is_dental_only: product.dental?, metal_level: product.metal_level, benefit_market_kind: product.benefit_market_kind.to_s,
                                product_kind: product.product_kind.to_s, issuer_profile_reference: {hbx_id: issuer.hbx_id, name: issuer.legal_name, abbrev: issuer.abbrev}},
            issuer_profile_reference: {hbx_id: issuer.hbx_id, name: issuer.legal_name, abbrev: issuer.abbrev},
            consumer_role_reference: {is_active: consumer_role.is_active, is_applying_coverage: consumer_role.is_applying_coverage, is_applicant: consumer_role.is_applicant, is_state_resident: consumer_role.is_state_resident,
                                      lawful_presence_determination: {}, citizen_status: consumer_role.citizen_status}
          }
        end
      end

      def build_payload(family_members_hash, households_hash)
        Success({family_members: family_members_hash, households: households_hash})
      end

      def validate_payload(payload)
        result = AcaEntities::Contracts::Families::FamilyContract.new.call(payload)

        Failure('invalid payload') unless result.success?
        Success(result.to_h)
      end

      def build_event(payload)
        result = event('events.individual.enrollments.submitted', attributes: payload)
        unless Rails.env.test?
          logger.info('-' * 100)
          logger.info(
            "Enroll Reponse Publisher to external systems(polypress),
            event_key: events.individual.enrollments.submitted, attributes: #{payload.to_h}, result: #{result}"
          )
          logger.info('-' * 100)
        end
        result
      end

      def publish_response(event)
        Success(event.publish)
      end
    end
  end
end
