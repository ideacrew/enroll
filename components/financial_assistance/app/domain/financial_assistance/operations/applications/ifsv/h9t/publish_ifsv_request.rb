# frozen_string_literal: true

require 'dry/monads'
require 'dry/monads/do'

module FinancialAssistance
  module Operations
    module Applications
      module Ifsv
        module H9t
          # publising request to H14 hub service for esi mec determination
          class PublishIfsvRequest
            send(:include, Dry::Monads[:result, :do, :try])
            include EventSource::Command

            def call(payload, application_id)
              event = yield build_event(payload, application_id)
              result = yield publish(event)

              Success(result)
            end

            private

            def build_event(payload, application_id)
              event('events.fti.ifsv.h9t.request_ifsv_determination', attributes: payload.to_h, headers: { correlation_id: application_id })
            end

            def publish(event)
              event.publish

              Success("Successfully published the payload to fti for ifsv determination")
            end
          end
        end
      end
    end
  end
end