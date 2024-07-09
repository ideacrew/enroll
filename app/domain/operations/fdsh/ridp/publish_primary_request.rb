# frozen_string_literal: true

require 'dry/monads'
require 'dry/monads/do'

module Operations
  module Fdsh
    module Ridp
      # Publish class will build event and publish the payload
      class PublishPrimaryRequest
        include Dry::Monads[:do, :result]
        include EventSource::Command

        def call(payload)
          event  = yield build_event(payload)
          result = yield publish(event)

          Success(result)
        end

        private

        def build_event(payload)
          hbx_id = payload.to_h[:family_members].detect{|fm| fm[:is_primary_applicant] == true}[:person][:hbx_id]
          event('events.fdsh.ridp.primary_determination_requested', attributes: payload.to_h, headers: { correlation_id: hbx_id, payload_format: EnrollRegistry[:ridp_h139].setting(:payload_format).item })
        end

        def publish(event)
          event.publish

          Success("Successfully published the payload to fdsh_gateway")
        end
      end
    end
  end
end
