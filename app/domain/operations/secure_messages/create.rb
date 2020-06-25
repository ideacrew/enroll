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

        Success(payload)
      end

      private

      def construct_message_payload(message_params)
        Success(message_params.merge!(from: site_short_name))
      end
    end
  end
end
