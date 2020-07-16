# frozen_string_literal: true

require 'dry/monads'
require 'dry/monads/do'

module Operations
  module Cartafact
    class Upload
      send(:include, Dry::Monads[:result, :do, :try])

      def call(resource:, file_params:, user:)
        if resource.blank?
          return Failure({:message => ['Please find valid resource to create document.']})
        end
        payload = construct_file_payload(resource, user)
        response = upload_to_doc_storage(resource, fetch_url, payload.to_json, fetch_doc_storage_key, file_params)
        validated_params = yield validate_params(response.transform_keys(&:to_sym))
        file_entity = yield create_file_entity(validated_params)
        file = yield create_document(resource, file_params, file_entity.to_h)
        Success(file)
      end

      private

      def validate_params(params)
          result = ::Validators::Cartafact::UploadContract.new.call(params)
          result.success? ? Success(result.to_h) : Failure(result.errors.to_h)
      end

      def create_file_entity(params)
        message = ::Entities::Cartafact::Upload.new(params.transform_keys(&:to_sym))
        Success(message)
      end

      def create_document(resource, file_params, file_entity)
        document_result = yield Operations::Documents::Create.new.call(resource: resource, document_params: file_params, doc_identifier: file_entity[:id])
        Success(document_result)
      end

      def encoded_payload(payload)
        Base64.strict_encode64(payload)
      end

      def fetch_file(file_params)
        file_params[:file].tempfile
      end

      def fetch_doc_storage_key
        Rails.application.secrets.secret_key_base
      end

      def fetch_url
        Rails.application.config.cartafact_document_upload_url
      end

      def upload_to_doc_storage(resource, url, payload, key, file_params)
        HTTParty.post(url, :body => {
                             document: {subjects: [{id: resource.id.to_s, type: resource.class.to_s}], document_type: 'notice'}.to_json,
                             content: fetch_file(file_params) },
                      :headers => { 'X-RequestingIdentity' => encoded_payload(payload),
                                    'X-RequestingIdentitySignature' => Base64.strict_encode64(OpenSSL::HMAC.digest("SHA256", key, encoded_payload(payload)))} ) if Rails.env.production?
        test_env_response(resource) if Rails.env.development?
      end

      def test_env_response(resource)
        {"title"=>"untitled",
         "language"=>"en",
         "format"=>"application/octet-stream",
         "source"=>"enroll_system",
         "type"=>"notice",
         "subjects"=>[{"id"=>resource.id.to_s, "type"=>resource.class.to_s}],
         "id"=> BSON::ObjectId.new.to_s,
         "extension"=>"pdf"
         }
      end

      def construct_file_payload(resource, user)
        {  "authorized_identity": {"user_id": user.id.to_s, "system": "enroll_dc"},
           "authorized_subjects": [{"type": "notice", "id": resource.id.to_s}]}
      end
    end
  end
end