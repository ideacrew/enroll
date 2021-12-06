# frozen_string_literal: true

require 'dry/monads'
require 'dry/monads/do'

module Enterprise
  class AdvanceDate
    send(:include, Dry::Monads[:result, :do, :try])
    include EventSource::Command

    def call(params)
      payload = yield validate(params)
      event = yield build_event(payload)
      yield publish_event(event)

      Success(model)
    end

    private

    def validate(params)
      if params[:date_of_record].blank? 
        Failure("Missing date of record")
      elsif !params[:date_of_record].is_a?(Date) 
        Failure("Expected Date kind for date_of_record. Instead got #{params[:date_of_record].class}")
      else
        Success(params.slice(:date_of_record))
      end
    end

    def build_event(payload, event_name)
      result = event('events.enterprise.date_advanced', attributes: payload)

      unless Rails.env.test?
        logger.info('-' * 100)
        logger.info(
          "Enroll publish advance date event,
          event_key: events.enterprise.date_advanced, attributes: #{payload.to_h}, result: #{result}"
        )
        logger.info('-' * 100)
      end
      result
    end

    def publish_response(event)
      Success(event.publish)
    end
  end
end
