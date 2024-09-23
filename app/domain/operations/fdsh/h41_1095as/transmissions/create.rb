# frozen_string_literal: true

module Operations
  module Fdsh
    module H411095as
      module Transmissions
        # Send transmission request to generate h41 and 1095a
        class Create
          include Dry::Monads[:do, :result]
          include EventSource::Command

          REPORT_TYPES = %w[all original corrected void].freeze

          REPORT_KINDS = %w[h41_1095a h41].freeze

          # @param [String] assistance_year
          # @param [Array] report_types
          # @param [Array] excluded_policies
          # @param [String] report_kind default value 'h41_1095a'
          def call(params)
            values = yield validate(params)
            event = yield build_event(values)
            result = yield publish(event)

            Success(result)
          end

          private

          def validate(params)
            params[:report_types]&.map!(&:to_s)
            params[:report_kind] = 'h41_1095a' if params[:report_kind].blank?

            errors = []
            errors << 'assistance_year required' unless params[:assistance_year]
            errors << 'report_types required' unless params[:report_types]
            if params[:report_types] &&
               (params[:report_types] - REPORT_TYPES).any?
              errors << 'invalid report_types'
            end
            errors << 'invalid report_kind' if REPORT_KINDS.exclude?(params[:report_kind])

            return Failure(errors) if errors.present?
            Success(params)
          end

          def build_event(values)
            event =
              event(
                'events.h41_1095as.transmission_requested',
                attributes: {
                  allow_list: values[:allow_list],
                  deny_list: values[:deny_list]
                },
                headers: values.slice(:assistance_year, :report_types, :report_kind)
              )

            Success(event.success)
          end

          def publish(event)
            event.publish

            Success("Successfully published the payload for event with name: #{event.name}")
          end
        end
      end
    end
  end
end
