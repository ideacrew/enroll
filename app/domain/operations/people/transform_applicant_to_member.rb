# frozen_string_literal: true

require 'dry/monads'
require 'dry/monads/do'

module Operations
  module People
    # Class for transforming applicant parameters to member parameters
    class TransformApplicantToMember
      include Dry::Monads[:result, :do]

      # Transforms the applicant parameters to member parameters.
      #
      # @param params [Hash] The parameters for transforming the applicant to a member.
      # @option params [Boolean] :skip_consumer_role_callbacks Additional param whether to skip consumer role callbacks.
      # @return [Dry::Monads::Result] The result of the operation is member hash.
      def call(params)
        applicant_params = yield validate(params)
        person_hash = yield initialize_person(applicant_params)
        consumer_role_hash = yield initialize_consumer_role(applicant_params)
        vlp_document_hash = yield initialize_vlp_document(applicant_params)
        member_hash = yield build_payload(person_hash.to_h, consumer_role_hash.to_h, vlp_document_hash.to_h, applicant_params)

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

      # if us_citizen, clear all vlp values
      def build_payload(person_hash, consumer_role_hash, vlp_document_hash, params)
        person_hash[:relationship] = params[:relationship]
        person_hash[:person_addresses] = person_hash.delete :addresses
        person_hash[:person_phones] = person_hash.delete :phones
        person_hash[:person_emails] = person_hash.delete :emails
        person_hash[:skip_person_updated_event_callback] = params[:skip_person_updated_event_callback]
        person_hash[:consumer_role] = {
          skip_consumer_role_callbacks: params[:skip_consumer_role_callbacks],
          **consumer_role_hash,
          immigration_documents_attributes: [vlp_document_hash].reject(&:empty?)
        }
        person_hash[:consumer_role][:immigration_documents_attributes] = [] if person_hash[:consumer_role][:citizen_status] == 'us_citizen'
        person_hash[:demographics_group] = {
          alive_status: {
            is_deceased: false,
            date_of_death: nil
          }
        }

        Success(person_hash)
      end
    end
  end
end
