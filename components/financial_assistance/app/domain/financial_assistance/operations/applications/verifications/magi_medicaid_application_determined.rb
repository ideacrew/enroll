# frozen_string_literal: true

require 'dry/monads'
require 'dry/monads/do'

module FinancialAssistance
  module Operations
    module Applications
      module Verifications
          # publising request to H14 hub service for esi mec determination
        class MagiMedicaidApplicationDetermined
          send(:include, Dry::Monads[:result, :do, :try])
          include EventSource::Command

          def call(payload, application_id, local_mec_check)
            event = yield build_event(payload, application_id, local_mec_check)
            result = yield publish(event)

            Success(result)
          end

          private

          def build_event(payload, application_id, local_mec_check)
            headers = { correlation_id: application_id }
            headers = headers.merge!(payload_type: 'application', key: 'local_mec_check') if local_mec_check
            event('events.iap.applications.magi_medicaid_application_determined', attributes: payload.to_h, headers: headers.merge!(payload_format))
          end

          def payload_format
            {
              non_esi_payload_format: EnrollRegistry[:non_esi_h31].setting(:payload_format).item,
              esi_mec_payload_format: EnrollRegistry[:esi_mec].setting(:payload_format).item
            }
          end

          def publish(event)
            event.publish

            Success("Successfully published the payload for FDSH")
          end
        end
      end
    end
  end
end
