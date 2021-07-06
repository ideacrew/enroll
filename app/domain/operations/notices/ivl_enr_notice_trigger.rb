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

      def call(params:)
        _values = yield validate(params)
        # raw_payload = yield build_payload(values[:enrollment])
        # validated_payload = yield validate_payload(raw_payload)
        event = yield build_event({})
        result = yield publish_response(event)

        Success(result)
      end

      private

      def validate(params)
        return Failure('Missing Enrollment') unless params[:enrollment].blank?

        Success(params)
      end

      # def build_payload(enrollment)
      #   family = enrollment.family

      #   family_members_hash = family.family_members.collect do |fm|
      #     person = fm.person
      #     {
      #       is_primary_applicant: fm.is_primary_applicant,
      #       person: {
      #         person_name: { first_name: person.first_name, last_name: person.last_name },
      #         person_demographics: { ssn: person.ssn, gender: person.gender, dob: person.dob, is_incarcerated: person.is_incarcerated },
      #         person_health: { is_tobacco_user: person.is_tobacco_user },
      #         is_active: person.is_active,
      #         is_disabled: person.is_disabled
      #       }
      #     }
      #   end

      #   households_hash = family.households.collect do |household|
      #     enrollments = household.hbx_enrollments.enrolled.with_product.by_year(enrollment.effective_on.year)
      #     {
      #       start_date: household.effective_starting_on,
      #       is_active: household.is_active,
      #       irs_group_reference: {},
      #       coverage_households: household.coverage_households.collect { |ch| {is_immediate_family: ch.is_immediate_family, coverage_household_members: ch.coverage_household_members.collect {|chm| {is_subscriber: chm.is_subscriber}}} },
      #       hbx_enrollments: enrollments.collect do |enr|
      #         product = enr.product
      #         issuer = product.issuer_profile
      #         consumer_role = enr.consumer_role
      #         {
      #           effective_on: enr.effective_on,
      #           aasm_state: enr.aasm_state,
      #           market_place_kind: enr.kind,
      #           enrollment_period_kind: enr.enrollment_kind,
      #           product_kind: enr.coverage_kind,
      #           hbx_enrollment_members: enr.hbx_enrollment_members.collect do |hem|
      #                                     {family_member_reference: {family_member_hbx_id: hem.hbx_id}, is_subscriber: hem.is_subscriber, eligibility_date: hem.eligibility_date, coverage_start_on: hem.coverage_start_on}
      #                                   end,
      #           product_reference: {hios_id: product.hios_id, name: product.title, active_year: product.active_year, is_dental_only: product.dental?, metal_level: product.metal_level, benefit_market_kind: product.benefit_market_kind.to_s,
      #                               product_kind: product.product_kind.to_s, issuer_profile_reference: {hbx_id: issuer.hbx_id, name: issuer.legal_name, abbrev: issuer.abbrev}},
      #           issuer_profile_reference: {hbx_id: issuer.hbx_id, name: issuer.legal_name, abbrev: issuer.abbrev},
      #           consumer_role_reference: {is_active: consumer_role.is_active, is_applying_coverage: consumer_role.is_applying_coverage, is_applicant: consumer_role.is_applicant, is_state_resident: consumer_role.is_state_resident,
      #                                     lawful_presence_determination: {}, citizen_status: consumer_role.citizen_status}
      #         }
      #       end
      #     }
      #   end

      #   AcaEntities::Contracts::Families::FamilyContract.new.call({family_members: family_members_hash, households: households_hash})
      # end

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
