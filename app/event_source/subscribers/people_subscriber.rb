# frozen_string_literal: true

module Subscribers
  # Subscriber will receive request payload from EA to generate a renewal draft application
  class PeopleSubscriber
    include ::EventSource::Subscriber[amqp: 'enroll.people']

    subscribe(:on_person_saved) do |delivery_info, _metadata, response|
      subscriber_logger = subscriber_logger_for(:on_person_saved)
      payload = JSON.parse(response, symbolize_names: true)
      pre_process_message(subscriber_logger, payload)
      # Add subscriber operations below this line
      redetermine_family_eligibility(payload)

      ack(delivery_info.delivery_tag)
    rescue StandardError, SystemStackError => e
      subscriber_logger.info "PeopleSubscriber, payload: #{payload}, error message: #{e.message}, backtrace: #{e.backtrace}"
    #   logger.info "PeopleSubscriber: errored & acked. Backtrace: #{e.backtrace}"
      subscriber_logger.info "PeopleSubscriber, ack: #{payload}"
      ack(delivery_info.delivery_tag)
    end

    def redetermine_family_eligibility(payload)
      person = GlobalID::Locator.locate(payload[:gid])

      person.families.each do |family|
        ::Operations::Eligibilities::BuildFamilyDetermination.new.call(
          family: person.primary_family,
          effective_date: TimeKeeper.date_of_record
        )
      end
    end

    private

    def pre_process_message(subscriber_logger, payload)
    #   logger.info '-' * 100 unless Rails.env.test?
      subscriber_logger.info "PeopleSubscriber, response: #{payload}"
    #   logger.info "PeopleSubscriber payload: #{payload}" unless Rails.env.test?
    end

    def subscriber_logger_for(event)
      Logger.new(
        "#{Rails.root}/log/#{event}_#{TimeKeeper.date_of_record.strftime('%Y_%m_%d')}.log"
      )
    end    
  end
end
