# frozen_string_literal: true

require 'dry/monads'
require 'dry/monads/do'

module Operations
  class SecureMessageAction
    send(:include, Dry::Monads[:result, :do, :try])

    def call(params)
      validate_params = yield validate_params(params)
      resource = yield fetch_resource(validate_params)
      result = yield upload_secure_message(resource, validate_params)

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

    def upload_secure_message(resource, params)
      ::Operations::SecureMessages::Create.new.call(resource: resource, message_params: params)
    end

  end
end
