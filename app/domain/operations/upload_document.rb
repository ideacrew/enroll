# frozen_string_literal: true

require 'dry/monads'
require 'dry/monads/do'

module Operations
  class UploadDocument
    send(:include, Dry::Monads[:result, :do])

    def call(person_id:, file_path:)
      person = yield fetch_person(person_id)
      generate_payload = yield construct_payload(person, file_path)
      url = yield fetch_url
      headers = yield  fetch_headers
      call_document_upload_service(generate_payload, url, headers)
    end


    private

    def fetch_url
      url = "http://localhost:4000/api/v1/documents/upload"
      Success(url)
    end

    def fetch_headers
      headers_hash =  { 'content-Type' => 'application/json' }
      Success(headers_hash)
    end

    def fetch_person(person_id)
      person = ::Person.where(_id: person_id).first
      person ? Success(person) : Failure([:danger, 'Person not found'])
    end

    def construct_payload(person, file_path)
      payload = {
        "authorized_identity": {"user_id": person.user.id.to_s, "system": "enroll"},
        "authorized_subjects": [{"id": person.user.id.to_s, "type": "consumer"}],
        "path": file_path,
        "document_type": "vlp_document"
      }
      Success(payload)
    end

    def call_document_upload_service(payload, url, headers)
      result = ::Validators::PayloadContract.new.call({url: url, payload: payload, headers: headers})
      if result.success?
        entity = ::Entities::Payload.new(result.to_h)
        service_result = call_doc_service(entity.to_h)
        validate_result = ::Validators::ResultContract.new.call(service_result.symbolize_keys)
        binding.pry
        if validate_result.success?
          Success({result: validate_result})
        else
          Failure({errors: validate_result.errors.to_h})
        end
      else
        Failure({errors: result.errors.to_h})
      end
    end

    def call_doc_service(entity)
      HTTParty.post(entity[:url], :body => entity[:payload], :headers => entity[:headers])
    end
  end
end