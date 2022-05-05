# frozen_string_literal: true

require 'dry/monads'
require 'dry/monads/do'

module Operations
    module Fdsh
        class RidpRepingService
            include Dry::Monads[:result, :do, :try]
            include EventSource::Command
            PublishEventStruct = Struct.new(:name, :payload, :headers)

            PUBLISH_EVENT = "fdsh_primary_determination_requested"

            # @param params [String] the json payload of the family
            # @return [Dry::Monads::Result]
            def call(payload, options)
              yield publish_event(payload, options)

              Success(true)
            end

            protected
        
            # Re-enable once soap is fixed.
            def publish_event(payload, options)
              event = PublishEventStruct.new(PUBLISH_EVENT, payload, options)

              Success(Publishers::RidpServicePublisher.publish(event))
            end
        end
    end
end