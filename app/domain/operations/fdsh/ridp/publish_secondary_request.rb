# frozen_string_literal: true

require 'dry/monads'
require 'dry/monads/do'

module Operations
  module Fdsh
    module Ridp
      # Publish class will build event and publish the payload
      class PublishSecondaryRequest
        include Dry::Monads[:do, :result]
        include EventSource::Command

        def call(payload, session_id, transmission_id)
          event  = yield build_event(payload, session_id, transmission_id)
          result = yield publish(event)

          Success(result)
        end

        private

        def build_event(payload, session_id, transmission_id)
          hbx_id = payload.to_h[:family_members].detect{|fm| fm[:is_primary_applicant] == true}[:person][:hbx_id]
          event('events.fdsh.ridp.secondary_determination_requested', attributes: payload.to_h, headers: { correlation_id: hbx_id,
                                                                                                           payload_format: EnrollRegistry[:ridp_h139].setting(:payload_format).item,
                                                                                                           session_id: session_id,
                                                                                                           transmission_id: transmission_id})
        end

        def publish(event)
          event.publish

          Success("Successfully published the payload to fdsh_gateway")
        end
      end
    end
  end
end
