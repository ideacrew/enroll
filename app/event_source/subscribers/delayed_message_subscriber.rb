# frozen_string_literal: true

module Subscribers
    # Subscriber will receive Enterprise requests like date change
    class DelayedMessageSubscriber
      include ::EventSource::Subscriber[amqp: 'enroll.delayed_message.events']
  
      subscribe(
        :on_enroll_delayed_message_events
      ) do |delivery_info, metadata, response|
        logger.info '-' * 100 unless Rails.env.test?

        payload = JSON.parse(response, symbolize_names: true)

        puts "*****************************"
        puts metadata.inspect
        puts "*****************************"
  
        subscriber_logger =
          Logger.new(
            "#{Rails.root}/log/on_enroll_enterprise_events_#{TimeKeeper.date_of_record.strftime('%Y_%m_%d')}.log"
          )
  
        subscriber_logger.info "EnterpriseSubscriber#on_enroll_enterprise_events, response: #{payload}"
        logger.info "EnterpriseSubscriber#on_enroll_enterprise_events payload: #{payload}" unless Rails.env.test?

        EventSource::Operations::DelayedMessageHandler.new.call(payload[:payload], metadata)

        ack(delivery_info.delivery_tag)
      rescue StandardError, SystemStackError => e
        subscriber_logger.info "EnterpriseSubscriber, payload: #{payload}, error message: #{e.message}, backtrace: #{e.backtrace}"
        logger.info "EnterpriseSubscriber: errored & acked. Backtrace: #{e.backtrace}"
        subscriber_logger.info "EnterpriseSubscriber, ack: #{payload}"
        ack(delivery_info.delivery_tag)
      end
    end
end