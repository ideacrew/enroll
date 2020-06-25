# frozen_string_literal: true

require 'dry/monads'
require 'dry/monads/do'

module Operations
  module SecureMessages
    class Create
      include Config::SiteConcern
      send(:include, Dry::Monads[:result, :do])

      def call(params)
        payload = yield construct_message_payload(params[:message_params])
        validated_payload = yield validate_message_payload(payload)

        Success(validated_payload)
      end

      private

      def construct_message_payload(message_params)
        Success(message_params.merge!(from: site_short_name))
      end

      def validate_message_payload(params)
        result = ::Validators::MessageContract.new.call(params)
        result.success? ? Success(result.to_h) : Failure(result.errors.to_h)
      end
      
    end
  end
end
