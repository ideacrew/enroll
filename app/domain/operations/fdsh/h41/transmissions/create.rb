# frozen_string_literal: true

module Operations
  module Fdsh
    module H41
      module Transmissions
        # Send transmission request to generate h41 and 1095a
        class Create
          send(:include, Dry::Monads[:result, :do, :try])
          include EventSource::Command
          REPORT_TYPES = %i[all original corrected voided].freeze

          # @param [String] assistance_year
          # @param [Array] report_types
          # @param [Array] excluded_policies
          def call(params)
            values = yield validate(params)
            event = yield build_event(values)
            result = yield publish(event)

            Success(result)
          end

          private

          def validate(params)
            params[:report_types]&.map!(&:to_sym)

            errors = []
            errors << 'assistance_year required' unless params[:assistance_year]
            errors << 'report_types required' unless params[:report_types]
            errors << 'invalid report_types' if params[:report_types] && (params[:report_types] - REPORT_TYPES).any?

            return Failure(errors) if errors.present?
            Success(params)
          end

          def build_event(values)
            event =
              event(
                'events.h41.transmissions.create_requested',
                attributes: {
                  excluded_policies: values[:excluded_policies]
                },
                headers: values.slice(:assistance_year, :report_types)
              )

            Success(event.success)
          end

          def publish(event)
            event.publish

            Success('Successfully published the payload to fdsh_gateway')
          end
        end
      end
    end
  end
end
