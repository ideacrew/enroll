# frozen_string_literal: true

require 'dry/monads'
require 'dry/monads/do'

module Operations
  module Eligibilities
    module Notices
      # Create document reminder notice for the family
      class CreateReminderRequest
        include Dry::Monads[:do, :result]
        include EventSource::Command
        include EventSource::Logging

        # @param [Hash] opts Options to trigger document reminder notice requests
        # @option opts [Date] :date_of_record required
        # @option opts [Family] :family required
        # @option opts [String] :document_reminder_key required
        # @return [Dry::Monad] result
        def call(params)
          values = yield validate(params)
          cv_payload = yield create_cv_payload(values)
          event = yield build_event(cv_payload, values)
          yield publish(event)

          Success(event)
        end

        private

        def validate(params)
          errors = []
          errors << 'date of record missing' unless params[:date_of_record]
          errors << 'family missing' unless params[:family]
          errors << 'document reminder key missing' unless params[:document_reminder_key]

          errors.empty? ? Success(params) : Failure(errors)
        end

        def create_cv_payload(values)
          BuildCvPayload.new.call(family: values[:family])
        end

        def build_event(payload, values)
          event_name =
            EnrollRegistry[values[:document_reminder_key]].settings(:event_name)
                                                          .item
          event_key = "events.individual.notices.#{event_name}"

          result = event(event_key, attributes: payload)
          unless Rails.env.test?
            logger.info('-' * 100)
            logger.info(
              "Enroll Reponse Publisher to external systems(polypress),
            event_key: #{event_key}, attributes: #{payload.to_h}, result: #{result}"
            )
            logger.info('-' * 100)
          end
          result
        end

        def publish(event)
          Success(event.publish)
        end
      end
    end
  end
end
