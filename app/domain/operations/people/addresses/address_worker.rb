# frozen_string_literal: true

module Operations
  module People
    module Addresses
      # This class is responsible for building payload and publishing event
      class AddressWorker
        include EventSource::Command
        include Dry::Monads[:result, :do]

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
          return Failure("AddressWorker: Person_hbx_id is missing") unless params[:person_hbx_id].present?
          return Failure("AddressWorker: address_id is missing") unless params[:address_id].present?

          Success(params)
        end

        def build_and_publish(valid_params)
          output = Operations::People::Addresses::Compare.new.call(valid_params)

          if output.success?
            payload = output.success.deep_symbolize_keys!
            logger << "\n"
            logger.info(payload[:person_hbx_id]) { "*" * 100 }

            event_payload = build_event_payload(payload)
            result = ::Operations::Events::BuildAndPublish.new.call(event_payload)

            logger.info(payload[:person_hbx_id]) { [result, {event_payload: event_payload}] }
          else
            logger.debug(payload[:person_hbx_id]) { output }
          end
          Success("AddressWorker: Completed")
        rescue StandardError => e
          logger.error(valid_params["person_hbx_id"]) { {Error: e.inspect} }
          Success("AddressWorker: Failed")
        end

        def build_event_payload(payload)
          headers = { correlation_id: payload[:person_hbx_id] }
          event_key = payload[:is_primary] ? "primary_member_address_relocated" : "member_address_relocated"

          {event_name: "events.families.family_members.#{event_key}", attributes: payload.to_h, headers: headers}
        end

        def logger
          @logger ||= Logger.new("#{Rails.root}/log/address_worker_#{TimeKeeper.date_of_record.strftime('%Y_%m_%d')}.log")
        end
      end
    end
  end
end
