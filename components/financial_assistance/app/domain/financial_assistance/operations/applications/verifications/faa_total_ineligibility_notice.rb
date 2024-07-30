# frozen_string_literal: true

require 'dry/monads'
require 'dry/monads/do'

module FinancialAssistance
  module Operations
    module Applications
      module Verifications
          # publishing request for FAA Total Ineligibility Notice
        class FaaTotalIneligibilityNotice
          include Dry::Monads[:do, :result]
          include EventSource::Command

          def call(payload)
            event = yield build_event(payload)
            result = yield publish(event)

            Success(result)
          end

          private

          def build_event(payload)
            event('events.families.notices.faa_totally_ineligible_notice.requested', attributes: payload)
          end

          def publish(event)
            event.publish

            Success("Successfully published the payload for FAA Total Ineligibility Notice")
          end
        end
      end
    end
  end
end
