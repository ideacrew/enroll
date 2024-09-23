# frozen_string_literal: true

require 'dry/monads'
require 'dry/monads/do'

module Operations
  module BrokerRole
    # Operation to find broker role.
    class Find
      include Dry::Monads[:do, :result]

      def call(obj_id)
        broker_role_id = yield validate(obj_id)
        broker = yield find_broker(broker_role_id)

        Success(broker)
      end

      private

      def validate(id)
        if id.present? && id.is_a?(BSON::ObjectId)
          Success(id)
        else
          Failure('id is nil or not in BSON format')
        end
      end

      def find_broker(broker_role_id)
        broker_role = ::BrokerRole.find(broker_role_id)

        broker_role.present? ? Success(broker_role) : Failure("Unable to find BrokerRole with ID #{broker_role_id}.")
      rescue StandardError
        Failure("Unable to find BrokerRole with ID2 #{broker_role_id}.")
      end
    end
  end
end
