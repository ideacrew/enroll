# frozen_string_literal: true

module Operations
  module Fdsh
    module PayloadEligibility
    # This class defines a set of validation rules for different types of eligibility requests.
    # The process method calls each validation rule for the given request type and returns a Success result if all rules pass, or a Failure result if any rule fails.
      class CheckPersonEligibilityRules < CheckBaseEligibilityRules

        private

        def validate(payload_entity, request_type)
          return Failure("Invalid Person Object #{payload_entity}") unless payload_entity.is_a?(::AcaEntities::People::Person)
          super(request_type)
        end

        def validate_ssn(payload)
          encrypted_ssn = payload.person_demographics.encrypted_ssn
          return Failure('No SSN') if encrypted_ssn.nil? || encrypted_ssn.empty?
          Operations::Fdsh::EncryptedSsnValidator.new.call(encrypted_ssn)
        end

        def validate_vlp_documents(person_entity)
          vlp_documents = person_entity.consumer_role.vlp_documents
          return Failure("No VLP Documents") if vlp_documents.empty?

          errors = vlp_documents.collect do |vlp_document_entity|
            next if vlp_document_entity.subject.nil?
            vlp_errors = AcaEntities::Fdsh::Vlp::H92::VlpV37Contract.new.call(JSON.parse(vlp_document_entity.to_json).compact).errors.to_h
            vlp_errors if vlp_errors.present?
          end.compact

          return Failure("Missing/Invalid information on vlp document") if errors.present?
          Success()
        end

        def validate_member_enrolled(person_entity)
          binding.irb
          # find_family using person entity
          # first check if eligibility_determination has family member as a subject
          subjects = family.eligibility_determination.subjects
          subject = subjects.detect { |sub| sub.hbx_id == person_entity.hbx_id }
          return false unless subject.present?

          # then check if subject has any of the valid eligibility states
          item_keys = ['health_product_enrollment_status', 'dental_product_enrollment_status']
          states = subject&.eligibility_states&.select { |state| item_keys.include?(state.eligibility_item_key) }
          return false unless states.present?

          # last check if valid eligibility states have is_eligible as true
          states.any?(&:is_eligible?)
        end
      end
    end
  end
end
