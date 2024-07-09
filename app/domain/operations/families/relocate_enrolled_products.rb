# frozen_string_literal: true

require 'dry/monads'
require 'dry/monads/do'

module Operations
  module Families
    # RelocateEnrolledProducts is a service class that will be used to relocate enrolled products for a given person, new address and existing coverage
    class RelocateEnrolledProducts
      include Dry::Monads[:do, :result]

      EVENT_OUTCOME_MAPPING = {:service_area_changed => "product_service_area_relocated",
                               :rating_area_changed => "premium_rating_area_relocated",
                               :no_change => "no_change"}.freeze

      # @param [Hash] params
      # @option params [String] :person_hbx_id
      # @option params [String] :primary_family_id
      # @option params [Hash] :address_set
      # @option params [Hash] :modified_address
      # @option params [Hash] :original_address
      # @return [Dry::Monads::Result]
      #  Success => {enrollments_hash}
      def call(params)
        valid_params = yield validate(params)
        person = yield find_person(valid_params)
        families = yield find_families(person)
        all_enrollments = yield fetch_existing_coverage_by_families(families.map(&:id))
        filtered_enrollments = yield filter_enrollments(all_enrollments, valid_params[:primary_family_id], valid_params[:person_hbx_id])
        enrollments_hash = yield  check_service_area_change_for_enrollments(filtered_enrollments, valid_params[:address_set])
        enrollments_hash = yield  check_rating_area_change_for_enrollments(filtered_enrollments, enrollments_hash, valid_params[:address_set][:modified_address])
        find_event_outcome(enrollments_hash)
        action_on_enrollment(enrollments_hash)
        result = yield build_and_publish_enrollment_event(enrollments_hash)

        Success(result)
      end

      private

      def validate(params)
        return Failure("RelocateEnrolledProducts: Person_hbx_id is missing") unless params[:person_hbx_id].present?
        return Failure("RelocateEnrolledProducts: address_set is missing") unless params[:address_set].present?
        return Failure("RelocateEnrolledProducts: address_set should be of kind home") unless params[:address_set][:modified_address][:kind] == "home"

        Success(params)
      end

      def find_person(valid_params)
        Operations::People::Find.new.call({person_hbx_id: valid_params[:person_hbx_id]})
      end

      def find_families(person)
        families = person.families
        return Failure("RelocateEnrolledProducts: No families found for a given person") if families.blank?

        Success(families)
      end

      def fetch_existing_coverage_by_families(family_ids)
        all_enrollments = HbxEnrollment.where({:family_id.in => family_ids, :aasm_state => {"$in" => HbxEnrollment::ENROLLED_STATUSES }})
        Success(all_enrollments)
      end

      def filter_enrollments(all_enrollments, primary_family_id, _person_hbx_id)
        all_enrollments = all_enrollments.where(family_id: primary_family_id, kind: "individual")
        all_enrollments = all_enrollments.by_year(TimeKeeper.date_of_record.next_year.year) if TimeKeeper.date_of_record.month == 12
        return Failure("RelocateEnrolledProducts: No enrollments found for a given criteria") if all_enrollments.blank?

        Success(all_enrollments)
      end

      def check_service_area_change_for_enrollments(all_enrollments, address_set)
        hash = all_enrollments.each_with_object({}) do |enrollment, result|
          new_service_areas = fetch_service_area(address_set[:modified_address], enrollment)
          old_service_areas = fetch_service_area(address_set[:original_address], enrollment)
          result[enrollment.hbx_id] = {is_service_area_changed: old_service_areas != new_service_areas, product_offered_in_new_service_area: new_service_areas.include?(enrollment.product.service_area_id)}
        end

        Success(hash)
      end

      def fetch_service_area(address, enrollment)
        ::BenefitMarkets::Locations::ServiceArea.service_areas_for(
          Address.new(address),
          during: enrollment.effective_on
        ).map(&:id)
      end

      def check_rating_area_change_for_enrollments(all_enrollments, enrollments_hash, modified_address)
        all_enrollments.each do |enrollment|
          enrollments_hash[enrollment.hbx_id].merge!({is_rating_area_changed:  is_rating_area_changed?(enrollment, modified_address)})
        end

        Success(enrollments_hash)
      end

      def is_rating_area_changed?(enrollment, rating_address)
        enrollment_rating_area = enrollment.rating_area.exchange_provided_code
        address_rating_area = ::BenefitMarkets::Locations::RatingArea.rating_area_for(
          Address.new(rating_address),
          during: enrollment.effective_on
        )&.exchange_provided_code

        (enrollment_rating_area != address_rating_area)
      end

      def find_event_outcome(enrollments_hash)
        enrollments_hash.each do |k,v|
          result = ::HbxEnrollments::FindEnrollmentEventOutcome.call(is_service_area_changed: v[:is_service_area_changed], product_offered_in_new_service_area: v[:product_offered_in_new_service_area],
                                                                     is_rating_area_changed: v[:is_rating_area_changed])
          enrollments_hash[k].merge!({ event_outcome: result.event_outcome })
        end
        enrollments_hash
      end

      def action_on_enrollment(enrollments_hash)
        enrollments_hash.each do |k,v|
          result = ::HbxEnrollments::ExpectedEnrollmentAction.call(is_service_area_changed: v[:is_service_area_changed], product_offered_in_new_service_area: v[:product_offered_in_new_service_area],
                                                                   is_rating_area_changed: v[:is_rating_area_changed], event_outcome: v[:event_outcome])
          enrollments_hash[k].merge!({ expected_enrollment_action: result.action_on_enrollment })
        end
      end

      def build_and_publish_enrollment_event(enrollments_hash)
        enrollments_hash.each do |k,v|
          event_key = EVENT_OUTCOME_MAPPING[v[:event_outcome].to_sym]
          next if v[:expected_enrollment_action] == "No Action Required"
          return Failure(["RelocateEnrolledProducts: Event key is invalid", {request_payload: enrollments_hash}]) unless event_key.present?

          event_payload = build_event_payload(enrollments_hash[k].merge!(enrollment_hbx_id: k), event_key)
          publish_event(event_payload)
        end
        Success(enrollments_hash)
      end

      def publish_event(payload)
        ::Operations::Events::BuildAndPublish.new.call(payload)
      end

      def build_event_payload(payload, event_key)
        headers = { correlation_id: payload[:enrollment_hbx_id] }

        {event_name: "events.families.family_members.primary_family_member.#{event_key}", attributes:  payload.to_h, headers: headers}
      end
    end
  end
end

