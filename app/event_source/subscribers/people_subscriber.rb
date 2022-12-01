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
      subscriber_logger.info "PeopleSubscriber::Save, payload: #{payload}, error message: #{e.message}, backtrace: #{e.backtrace}"
      subscriber_logger.info "PeopleSubscriber::Save, ack: #{payload}"
      ack(delivery_info.delivery_tag)
    end

    subscribe(:on_person_updated) do |delivery_info, _metadata, response|
      subscriber_logger = subscriber_logger_for(:on_person_updated)
      payload = JSON.parse(response, symbolize_names: true)
      pre_process_message(subscriber_logger, payload)

      determine_verifications(payload, subscriber_logger) if !Rails.env.test? && EnrollRegistry.feature_enabled?(:consumer_role_hub_call)

      ack(delivery_info.delivery_tag)
    rescue StandardError, SystemStackError => e
      subscriber_logger.info "PeopleSubscriber::Update, payload: #{payload}, error message: #{e.message}, backtrace: #{e.backtrace}"
      subscriber_logger.info "PeopleSubscriber::Update,  ack: #{payload}"
      ack(delivery_info.delivery_tag)
    end

    def redetermine_family_eligibility(payload)
      person = GlobalID::Locator.locate(payload[:gid])

      person.families.each do |family|
        ::Operations::Eligibilities::BuildFamilyDetermination.new.call(
          family: family,
          effective_date: TimeKeeper.date_of_record
        )
      end
    end

    def determine_verifications(params, subscriber_logger)
      person = GlobalID::Locator.locate(params[:gid])
      consumer_role = person.consumer_role

      identifying_information_attributes = EnrollRegistry[:consumer_role_hub_call].setting(:identifying_information_attributes).item.map(&:to_sym)
      tribe_status_attributes = EnrollRegistry[:consumer_role_hub_call].setting(:indian_tribe_attributes).item.map(&:to_sym)
      valid_attributes = identifying_information_attributes + tribe_status_attributes
      if consumer_role.present? && (valid_attributes & params[:payload].keys).present?
        result = ::Operations::Individual::DetermineVerifications.new.call({id: consumer_role.id})
        result_str = result.success? ? "Success: #{result.success}" : "Failure: #{result.failure}"
        subscriber_logger.info "PeopleSubscriber::Update, determine_verifications result: #{result_str}"
      end
    rescue StandardError => e
      subscriber_logger.info "Error: PeopleSubscriber::Update, response: #{e}"
    end

    private

    def pre_process_message(subscriber_logger, payload)
      subscriber_logger.info "PeopleSubscriber, response: #{payload}"
    end

    def subscriber_logger_for(event)
      Logger.new(
        "#{Rails.root}/log/#{event}_#{TimeKeeper.date_of_record.strftime('%Y_%m_%d')}.log"
      )
    end
  end
end
