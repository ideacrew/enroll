# frozen_string_literal: true

module Subscribers
  # Subscriber will receive Enterprise requests like date change
  class FamilyPvcDeterminationSubscriber
    include ::EventSource::Subscriber[amqp: 'enroll.iap.family_pvc_determination.events']

    subscribe(
      :on_enroll_iap_family_pvc_determination_events
    ) do |delivery_info, _metadata, response|
      logger.info '-' * 100 unless Rails.env.test?

      payload = JSON.parse(response, symbolize_names: true)

      # subscriber_logger =
      #   Logger.new(
      #     "#{Rails.root}/log/on_enroll_iap_family_pvc_determination_events_#{TimeKeeper.date_of_record.strftime('%Y_%m_%d')}.log"
      #   )

      # subscriber_logger.info "FamilyPvcDeterminationSubscriber, response: #{payload}"

      # families = Family.where(:_id.in => payload[:families]).all
      # ::FinancialAssistance::Operations::Applications::Pvc::CreatePvcRequest.new.call(families: families, assistance_year: payload[:assistance_year])
      result = ::FinancialAssistance::Operations::Applications::Pvc::CreatePvcRequest.new.call(person: payload[:person], manifest: payload[:manifest], family_id: payload[:family_id])

      logger.info "FamilyPvcDeterminationSubscriber ACK/SUCCESS person payload: #{payload[:person][:hbx_id]} " if result.success?
      logger.error "FamilyPvcDeterminationSubscriber ACK/FAILURE person payload: #{payload[:person][:hbx_id]} - #{result.failure} " unless result.success?

      ack(delivery_info.delivery_tag)
    rescue StandardError, SystemStackError => e
      # subscriber_logger.error "FamilyPvcDeterminationSubscriber, payload: #{payload}, error message: #{e.message}, backtrace: #{e.backtrace}"
      logger.error "------------------------------------------------------------"
      logger.error "FamilyPvcDeterminationSubscriber error message: #{e.message}, backtrace: #{e.backtrace}"
      logger.error "FamilyPvcDeterminationSubscriber payload: #{payload} " 
      logger.error "------------------------------------------------------------"
      # subscriber_logger.error "FamilyPvcDeterminationSubscriber, ack: #{payload}"
      ack(delivery_info.delivery_tag)
    end
  end
end
