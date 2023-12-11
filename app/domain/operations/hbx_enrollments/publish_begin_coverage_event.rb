# frozen_string_literal: true

module Operations
    module HbxEnrollments
      # Publish event to begin IVL enrollment coverage
      class PublishBeginCoverageEvent
        include EventSource::Command
        include Dry::Monads[:result, :do]
  
        # @param [Hash] params
        # @option params [Hash] :
        # @return [Dry::Monads::Result]
        def call(params)
          enrollment_hbx_id = yield validate(params)
          event             = yield build_event(enrollment_hbx_id)
          result            = yield publish_event(event)
          Success(result)
        end

        private

        def validate(params)
          return Failure('Missing enrollment_hbx_id.') unless params.is_a?(Hash) && params[:enrollment_hbx_id].is_a?(String)

          Success(params[:enrollment_hbx_id])
        end

        def build_event(enrollment_hbx_id)
          # TODO: use global id instead of hbx_id
          event = event("events.individual.enrollments.begin_coverages.begin", attributes: { enrollment_hbx_id: enrollment_hbx_id })
          if event.success?
            event
          else
            Failure("Failure building event: #{event.failure}")
          end
        end
  
        def publish_event(event)
          result = event.publish
          if result
            Success("Successfully published begin coverage event.")
          else
            Failure("Failure publishing event.")
          end
        end
      end
    end
  end
  