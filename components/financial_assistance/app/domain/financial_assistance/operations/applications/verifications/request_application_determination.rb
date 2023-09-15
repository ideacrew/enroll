# frozen_string_literal: true

require 'dry/monads'
require 'dry/monads/do'

module FinancialAssistance
  module Operations
    module Applications
      module Verifications
        # This class is responsible for validating an application object and constructing a payload entity for FDSH service.
        class RequestApplicationDetermination
          include Dry::Monads[:result, :do]
          include EventSource::Command

          def call(application)
            payload_entity = yield validate_and_construct_application_payload(application)
            event_result = yield build_event(payload_entity, application)
            publish_result = yield publish_event_result(event_result)

            Success(publish_result)
          end

          private

          def validate_and_construct_application_payload(application)
            ::FinancialAssistance::Operations::Applications::Verifications::BuildAndValidateApplicationPayload.new.call(application)
          end

          def build_event(payload, application)
            local_mec_check = application.is_local_mec_checkable?
            headers = local_mec_check ? { payload_type: 'application', key: 'local_mec_check' } : { correlation_id: application.id }
            event('events.iap.applications.magi_medicaid_application_determined', attributes: payload.to_h, headers: headers.merge!(payload_format))
          end

          def payload_format
            {
              non_esi_payload_format: EnrollRegistry[:non_esi_h31].setting(:payload_format).item,
              esi_mec_payload_format: EnrollRegistry[:esi_mec].setting(:payload_format).item
            }
          end

          def publish_event_result(event_result)
            event_result.publish ? Success("Event published successfully") : Failure("Event failed to publish")
          end
        end
      end
    end
  end
end