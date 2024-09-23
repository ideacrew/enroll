# frozen_string_literal: true

module Operations
  module People
    module Addresses
      # This class is responsible for building payload and publishing event
      class AddressWorker
        include EventSource::Command
        include Dry::Monads[:do, :result]

        # @param [Hash] params
        # @option params [String] :person_hbx_id
        # @option params [String] :address_id
        # @return [Dry::Monads::Result]
        # @return Success monad if the operation is successful or Failure
        def call(params)
          valid_params = yield validate(params)
          result = yield build_and_publish(valid_params)

          Success(result)
        end

        private

        def validate(params)
          address_logger << "\n"

          unless params[:person_hbx_id].present?
            address_logger.debug(params) { "AddressWorker: Person_hbx_id is missing" }
            return Failure("AddressWorker: Person_hbx_id is missing")
          end

          address_logger.info(params[:person_hbx_id]) { "*" * 100 }

          unless params[:address_id].present?
            address_logger.debug(params[:person_hbx_id]) { "AddressWorker: address_id is missing" }
            return Failure("AddressWorker: address_id is missing")
          end

          Success(params)
        end

        def build_and_publish(valid_params)
          output = Operations::People::Addresses::Compare.new.call(valid_params)

          if output.success?
            payload = output.success.deep_symbolize_keys!
            event_payload = build_event_payload(payload)
            result = ::Operations::Events::BuildAndPublish.new.call(event_payload)

            address_logger.info(payload[:person_hbx_id]) { [result, {event_payload: event_payload}] }
          else
            address_logger.debug(payload[:person_hbx_id]) { output }
          end
          Success("AddressWorker: Completed")
        rescue StandardError => e
          address_logger.error(valid_params["person_hbx_id"]) { {Error: e.inspect} }
          Success("AddressWorker: Failed")
        end

        def build_event_payload(payload)
          headers = { correlation_id: payload[:person_hbx_id] }
          event_key = payload[:is_primary] ? "primary_member_address_relocated" : "member_address_relocated"

          {event_name: "events.families.family_members.#{event_key}", attributes: payload.to_h, headers: headers}
        end

        def address_logger
          @address_logger ||= Logger.new("#{Rails.root}/log/address_worker.log")
        end
      end
    end
  end
end
