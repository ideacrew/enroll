# frozen_string_literal: true

module Subscribers
  # Subscriber will receive Enterprise requests like date change
  class FamilyRrvDeterminationSubscriber
    include ::EventSource::Subscriber[amqp: 'enroll.iap.family_rrv_determination.events']

    subscribe(
      :on_enroll_iap_family_rrv_determination_events
    ) do |delivery_info, _metadata, response|
      logger.info '-' * 100 unless Rails.env.test?

      payload = JSON.parse(response, symbolize_names: true)

      subscriber_logger =
        Logger.new(
          "#{Rails.root}/log/on_enroll_iap_family_rrv_determination_events_#{TimeKeeper.date_of_record.strftime('%Y_%m_%d')}.log"
        )

      subscriber_logger.info "FamilyRrvDeterminationSubscriber, response: #{payload}"
      logger.info "FamilyRrvDeterminationSubscriber payload: #{payload}" unless Rails.env.test?

      families = Family.where(:_id.in => payload[:families]).all
      ::FinancialAssistance::Operations::Applications::Rrv::CreateRrvRequest.new.call(families: families, assistance_year: payload[:assistance_year])
      ack(delivery_info.delivery_tag)
    rescue StandardError, SystemStackError => e
      subscriber_logger.info "FamilyRrvDeterminationSubscriber, payload: #{payload}, error message: #{e.message}, backtrace: #{e.backtrace}"
      logger.info "FamilyRrvDeterminationSubscriber: errored & acked. Backtrace: #{e.backtrace}"
      subscriber_logger.info "FamilyRrvDeterminationSubscriber, ack: #{payload}"
      ack(delivery_info.delivery_tag)
    end
  end
end
