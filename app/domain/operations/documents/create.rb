# frozen_string_literal: true

require 'dry/monads'
require 'dry/monads/do'

module Operations
  module Documents
    class Create
      include Dry::Monads[:do, :result]

      def call(resource:, document_params:, doc_identifier:)
        return Failure({ :message => ["Please find valid resource to create document for params: #{document_params}"] }) if resource.blank?

        payload = yield construct_doc_payload(document_params, doc_identifier)
        validated_params = yield validate_params(payload)
        document_entity = yield create_document_entity(validated_params)
        document = yield create(resource, document_entity.to_h)
        Success(document)
      end

      private

      def validate_params(params)
        result = ::Validators::Documents::DocumentContract.new.call(params)
        result.success? ? Success(result.to_h) : Failure(result.errors.to_h)
      end

      def create_document_entity(params)
        entity = ::Entities::Documents::Document.new(params)
        Success(entity)
      end

      def create(resource, document_entity)
        document = resource.documents.build(document_entity)
        document.save!
        Success(document)
      end

      def construct_doc_payload(params, doc_identifier)
        Success({ "title": params[:file_name],
                  "format": params[:file_content_type],
                  "creator": "hbx_staff",
                  "subject": "notice",
                  "doc_identifier": doc_identifier })
      end
    end
  end
end
