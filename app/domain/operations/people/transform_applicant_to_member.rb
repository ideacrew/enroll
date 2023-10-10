# frozen_string_literal: true

require 'dry/monads'
require 'dry/monads/do'

module Operations
  module People
    class TransformApplicantToMember
      include Dry::Monads[:result, :do]

      def call(params)
        applicant_params = yield validate(params)
        person_hash = yield initialize_person(applicant_params)
        consumer_role_hash = yield initialize_consumer_role(applicant_params)
        vlp_document_hash = yield initialize_vlp_document(applicant_params)
        member_hash = yield build_payload(person_hash.to_h, consumer_role_hash.to_h, vlp_document_hash.to_h)

        Success(member_hash)
      end

      private

      def validate(params)
        return Failure("Provide applicant_params for transformation") if params.blank?
        Success(params)
      end

      def find_family(family_id)
        Operations::Families::Find.new.call(id: BSON::ObjectId(family_id))
      end

      def initialize_person(params)
        Operations::People::InitializePerson.new.call(params)
      end

      def initialize_consumer_role(params)
        Operations::People::InitializeConsumerRole.new.call(params)
      end

      def initialize_vlp_document(params)
        Operations::People::InitializeVlpDocument.new.call(params)
      end

      def build_payload(person_hash, consumer_role_hash, vlp_document_hash)
        person_hash[:addresses_attributes] = person_hash.delete :addresses
        person_hash[:phones_attributes] = person_hash.delete :phones
        person_hash[:emails_attributes] = person_hash.delete :emails
        person_hash.merge!(consumer_role: { **consumer_role_hash, vlp_documents_attributes: [vlp_document_hash] })

        Success(person_hash)
      end
    end
  end
end
