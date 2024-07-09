# frozen_string_literal: true

require 'dry/monads'
require 'dry/monads/do'

module Operations
  module People
    # Class for creating and uploading VLP Documents
    class CreateOrUpdateVlpDocument
      include Dry::Monads[:do, :result]

      def call(params:)
        values = yield validate(params[:applicant_params])
        vlp_document_params = yield create_entity(values)
        vlp_document = yield create_or_update_vlp_document(vlp_document_params, params[:person])

        Success(vlp_document)
      end

      private

      def sanitize_params(params)
        params[:subject] = params.delete :vlp_subject if params[:vlp_subject]
        params[:description] = params.delete :vlp_description if params[:vlp_description]
        params
      end

      def validate(params)
        result = Validators::Families::VlpDocumentContract.new.call(sanitize_params(params))

        if result.success?
          Success(result)
        else
          Failure(result)
        end
      end

      def create_entity(values)
        result = Entities::VlpDocument.new(values.to_h)

        Success(result)
      rescue StandardError => e
        Failure("create_entity error: #{e}")
      end

      def create_or_update_vlp_document(vlp_document_params, person)
        # (REF pivotal ticket: 178800234) Whenever this class is called to create_or_update_vlp_document, below code is overriding vlp_document_params and only creates document for income subject.
        # This code is blocking ATP and MCR migration for vlp data, commenting below code as this does not make anysense to override the incoming vlp_document_params
        # refactor this accordingly based on requirement
        # vlp_document_params = {subject: "Income", description: "Income Verification Needed"} if EnrollRegistry.feature_enabled?(:verification_type_income_verification) && vlp_document_params[:incomes].blank?
        vlp_document = person.consumer_role.find_document(vlp_document_params[:subject])
        return Success(vlp_document) if no_update_needed?({vlp_object: vlp_document, vlp_document_params: vlp_document_params})
        vlp_document.assign_attributes(vlp_document_params.to_h)
        person.consumer_role.active_vlp_document_id = vlp_document.id
        person.save!

        Success(vlp_document)
      rescue StandardError => e
        Failure("create_or_update failure: #{e}")
      end

      def no_update_needed?(params)
        vlp_db_hash = params[:vlp_object].serializable_hash
        vlp_db_hash.merge(params[:vlp_document_params]) == vlp_db_hash
      end
    end
  end
end

