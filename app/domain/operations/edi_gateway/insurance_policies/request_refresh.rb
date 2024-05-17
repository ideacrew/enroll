# frozen_string_literal: true

require 'dry/monads'
require 'dry/monads/do'

module Operations
  module EdiGateway
    module InsurancePolicies
      # Operation to publish an event to request refresh of insurance policies within a date range(refresh_period).
      class RequestRefresh
        include Dry::Monads[:do, :result]
        include EventSource::Command

        def call(params)
          validated_params = yield validate(params)
          event            = yield build_event(validated_params)
          publish_result   = yield publish(event)

          Success(publish_result)
        end

        private

        def build_event(validated_params)
          event('events.insurance_policies.refresh_requested', attributes: { header: { refresh_period: validated_params[:refresh_period] }, payload: {} })
        end

        def formatted_params(params)
          refresh_period_range = params[:refresh_period]
          refresh_period_range = refresh_period_range.min.utc..refresh_period_range.max.utc
          params[:refresh_period] = refresh_period_range
          params
        end

        def publish(event)
          event.publish
          Success("Successfully published event: #{event.name}")
        end

        def validate(params)
          if valid_date_range?(params[:refresh_period])
            Success(formatted_params(params))
          else
            Failure('refresh_period must be a range with timestamps and max timestamps must be equal to or less than current time.')
          end
        end

        def valid_date_range?(date_range)
          return false unless date_range.is_a?(Range)
          return false unless date_range.min.is_a?(Time) && date_range.max.is_a?(Time)

          date_range.min <= date_range.max &&
            date_range.max.utc <= Time.now.utc
        end
      end
    end
  end
end
