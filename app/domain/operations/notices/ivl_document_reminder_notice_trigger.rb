# frozen_string_literal: true

require 'dry/monads'
require 'dry/monads/do'

module Operations
  module Notices
    # IVL document reminder notice
    class IvlDocumentReminderNoticeTrigger
      include Dry::Monads[:result, :do]
      include EventSource::Command
      include EventSource::Logging

      # @param [Family] Family object (required)
      # @param [String] :event_name (required)
      # @return [Dry::Monads::Result]

      def call(params)
        _values = yield validate(params)
        fm_hash = yield build_family_member_hash(params[:family])
        household_hash = yield build_household_hash(params[:family])
        payload = yield build_payload(fm_hash, household_hash, params[:family])
        validated_payload = yield validate_payload(payload)
        entity_result = yield through_entity(validated_payload)
        event = yield build_event(entity_result, params[:event_name])
        result = yield publish_response(event)

        Success(result)
      end

      private

      def validate(params)
        return Failure('Missing family') if params[:family].blank?

        Success(params)
      end

      def build_addresses(person)
        address = person.mailing_address
        [
          {
            :kind => address.kind,
            :address_1 => address.address_1.presence,
            :address_2 => address.address_2.presence,
            :address_3 => address.address_3.presence,
            :state => address.state,
            :city => address.city,
            :zip => address.zip
          }
        ]
      end

      def update_and_build_verification_types(person)
        person.consumer_role.types_include_to_notices.collect do |verification_type|
          {
            type_name: verification_type.type_name,
            validation_status: verification_type.validation_status,
            due_date: verification_type.due_date
          }
        end
      end

      def enrollments(household)
        date = TimeKeeper.date_of_record
        HbxEnrollment.where(
          :family_id => household.family.id,
          :household_id => household.id,
          :effective_on.gte => date.beginning_of_year,
          :effective_on.lte => date.end_of_year,
          :kind.nin => %w[employer_sponsored employer_sponsored_cobra],
          :aasm_state.nin => ["coverage_canceled", "shopping", "inactive", "coverage_terminated"],
          "$or" => [
            {"terminated_on" => nil},
            {"terminated_on" => {"$gte" => TimeKeeper.date_of_record}}
          ]
        )
      end

      def build_family_member_hash(family)
        members = family.family_members
        family_members_hash = members.collect do |fm|
          person = fm.person
          outstanding_verification_types = person.consumer_role.types_include_to_notices
          member_hash = {
            is_primary_applicant: fm.is_primary_applicant,
            person: {
              hbx_id: person.hbx_id,
              person_name: { first_name: person.first_name, last_name: person.last_name },
              person_demographics: { ssn: person.ssn, gender: person.gender, dob: person.dob, is_incarcerated: person.is_incarcerated },
              person_health: { is_tobacco_user: person.is_tobacco_user },
              is_active: person.is_active,
              is_disabled: person.is_disabled,
              addresses: build_addresses(person)
            }
          }
          member_hash[:person].merge!(verification_types: update_and_build_verification_types(person)) if outstanding_verification_types.present?
          member_hash
        end
        Success(family_members_hash)
      end

      def build_household_hash(family)
        household_hash = family.households.collect do |household|
          enrollments = enrollments(household)
          {
            start_date: household.effective_starting_on,
            is_active: household.is_active,
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
          enrollment_hash = {
            effective_on: enr.effective_on,
            aasm_state: enr.aasm_state,
            market_place_kind: enr.kind,
            enrollment_period_kind: enr.enrollment_kind,
            product_kind: enr.coverage_kind,
            total_premium: enr.total_premium,
            applied_aptc_amount: { cents: enr.applied_aptc_amount.cents, currency_iso: enr.applied_aptc_amount.currency.iso_code },
            hbx_enrollment_members: enrollment_member_hash(enr),
            product_reference: product_reference(product, issuer),
            issuer_profile_reference: issuer_profile_reference(issuer),
            consumer_role_reference: consumer_role_reference(consumer_role),
            is_receiving_assistance: (enr.applied_aptc_amount > 0 || (product.is_csr? ? true : false))
          }
          enrollment_hash.merge!(special_enrollment_period_reference: special_enrollment_period_reference(enr)) if enr.is_special_enrollment?
          enrollment_hash
        end
      end

      def qualifying_life_event_kind_reference(qle)
        qle_hash = {
          start_on: qle.start_on,
          title: qle.title,
          reason: qle.reason,
          market_kind: qle.market_kind
        }
        qle_hash.merge!(end_on: qle.end_on) if qle.end_on
        qle_hash
      end

      def special_enrollment_period_reference(enrollment)
        sep = enrollment.family.latest_active_sep
        qle = sep.qualifying_life_event_kind
        {
          qualifying_life_event_kind_reference: qualifying_life_event_kind_reference(qle),
          qle_on: sep.qle_on,
          start_on: sep.start_on,
          end_on: sep.end_on,
          effective_on: sep.effective_on,
          submitted_at: sep.submitted_at
        }
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
          abbrev: issuer.abbrev,
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

      def documents_needed(family)
        family.households.any? do |household|
          members = enrollments(household).flat_map(&:hbx_enrollment_members).map(&:family_member)
          members.any? { |member| member.person.consumer_role.types_include_to_notices.present? }
        end
      end

      def build_payload(family_members_hash, households_hash, family)
        Success({family_members: family_members_hash, households: households_hash, hbx_id: family.hbx_assigned_id.to_s, documents_needed: documents_needed(family)})
      end

      def validate_payload(payload)
        result = AcaEntities::Contracts::Families::FamilyContract.new.call(payload)

        return Failure('invalid payload') unless result.success?
        Success(result.to_h)
      end

      def through_entity(payload)
        Success(AcaEntities::Families::Family.new(payload).to_h)
      end

      def build_event(payload, event_name)
        result = event("events.individual.notices.#{event_name}", attributes: payload)
        unless Rails.env.test?
          logger.info('-' * 100)
          logger.info(
            "Enroll Reponse Publisher to external systems(polypress),
            event_key: events.individual.notices.#{event_name}, attributes: #{payload.to_h}, result: #{result}"
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
