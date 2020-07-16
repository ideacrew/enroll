# frozen_string_literal: true

require 'dry/monads'
require 'dry/monads/do'

module Operations
  class SecureMessageAction
    send(:include, Dry::Monads[:result, :do, :try])

    def call(params:, user:)
      validate_params = yield validate_params(params)
      resource = yield fetch_resource(validate_params)
      upload_doc_result = yield upload_document(resource, validate_params, user)
      secure_message_result = yield upload_secure_message(resource, validate_params)
      result = yield send_generic_notice_alert(secure_message_result)
      Success(result)
    end

    private

    def validate_params(params)
      result = ::Validators::SecureMessageActionContract.new.call(params)

      result.success? ? Success(result.to_h) : Failure(result.errors.to_h)
    end

    def fetch_resource(validate_params)
      if validate_params[:resource_name].classify.constantize == Person
        ::Operations::People::Find.new.call(person_id: validate_params[:resource_id])
      else
        BenefitSponsors::Operations::Profiles::FindProfile.new.call(profile_id: validate_params[:resource_id])
      end
    end

    def upload_document(resource, params, user)
      if params[:file].present?
        ::Operations::Cartafact::Upload.new.call(resource: resource, file_params: params, user: user)
      else
        Success(true)
      end
    end

    def upload_secure_message(resource, params)
      ::Operations::SecureMessages::Create.new.call(resource: resource, message_params: params)
    end

    def send_generic_notice_alert(resource)
      ::Operations::SendGenericNoticeAlert.new.call(resource: resource)
    end

  end
end