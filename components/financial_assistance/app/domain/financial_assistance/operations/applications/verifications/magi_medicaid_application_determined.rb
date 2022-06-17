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
            headers = local_mec_check ? { payload_type: 'application', key: 'local_mec_check' } : { correlation_id: application_id }
            event('events.iap.applications.magi_medicaid_application_determined', attributes: payload.to_h, headers: headers)
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