module TransportProfiles
  module Subscribers
    class TransportArtifactSubscriber < ::Acapi::Subscription
      include Acapi::Notifiers

      def self.subscription_details
        ["acapi.info.events.transport_artifact.transport_requested"]
      end

      def call(event_name, e_start, e_end, msg_id, payload)
        stringed_payload = payload.stringify_keys
        artifact_key = stringed_payload["artifact_key"]
        file_name = stringed_payload["file_name"]
        transport_process = stringed_payload["transport_process"]
        atr = ::TransportProfiles::ArtifactTransportRequest.new(
          :file_name => file_name,
          :artifact_key => artifact_key,
          :transport_process => transport_process
        )
        if !atr.valid?
          notify(
            "acapi.error.events.transport_artifact.invalid_transport_request",
            {
              :return_status => "422",
              :body => JSON.dump(
                atr.errors.to_hash
              )
            }
          )
          return
        end
        begin
          atr.execute
        rescue Exception => e
          notify(
            "acapi.error.events.transport_artifact.transport_execution_error",
            {
              :return_status => "500",
              :body => JSON.dump({
                 :error => e.inspect,
                 :error_message => e.message,
                 :error_backtrace => e.backtrace
              })
            }
          )
        end
      end
    end
  end
end
