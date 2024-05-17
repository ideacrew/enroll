# frozen_string_literal: true

module Operations
  module Fdsh
    module H36
      module Transmissions
        # Send transmission request to generate h36
        class Create
          include Dry::Monads[:do, :result]
          include EventSource::Command

          # @param [Integer] assistance_year
          # @param [Integer] month_of_year
          # @param [Array] allow_list
          # @param [Array] deny_list
          def call(params)
            values = yield validate(params)
            event =  yield build_event(values)
            result = yield publish(event)

            Success(result)
          end

          private

          def validate(params)
            errors = []
            errors << 'assistance_year must be a valid Integer' unless params[:assistance_year].is_a?(Integer)
            errors << 'month_of_year must be a valid Integer' unless params[:month_of_year].is_a?(Integer)

            errors.present? ? Failure(errors) : Success(params)
          end

          def build_event(values)
            event(
              'events.h36.transmission_requested',
              attributes: {
                allow_list: values[:allow_list].presence || [],
                deny_list: values[:deny_list].presence || []
              },
              headers: values.slice(:assistance_year, :month_of_year)
            )
          end

          def publish(event)
            event.publish

            Success("Successfully published payload with event: #{event.name}")
          end
        end
      end
    end
  end
end
