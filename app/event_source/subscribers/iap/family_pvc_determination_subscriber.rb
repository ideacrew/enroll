# frozen_string_literal: true

module Subscribers
  # Subscriber will receive Enterprise requests like date change
  class FamilyPvcDeterminationSubscriber
    include ::EventSource::Subscriber[amqp: 'enroll.iap.family_pvc_determination.events']

    subscribe(:on_enroll_iap_family_pvc_determination_events) do |delivery_info, _metadata, response|
      pvc_logger = Logger.new("#{Rails.root}/log/pvc_non_esi_logger_#{TimeKeeper.date_of_record.strftime('%Y_%m_%d')}.log")

      pvc_logger.info '-' * 100 unless Rails.env.test?

      payload = JSON.parse(response, symbolize_names: true)
      result = ::FinancialAssistance::Operations::Applications::Pvc::CreatePvcRequest.new.call({family_hbx_id: payload[:family_hbx_id],
                                                                                                application_hbx_id: payload[:application_hbx_id],
                                                                                                assistance_year: payload[:assistance_year]})

      pvc_logger.info "FamilyPvcDeterminationSubscriber ACK/SUCCESS payload: #{payload} " if result.success?
      pvc_logger.error "FamilyPvcDeterminationSubscriber ACK/FAILURE payload: #{payload} - #{result.failure} " unless result.success?

      ack(delivery_info.delivery_tag)
    rescue StandardError, SystemStackError => e
      pvc_logger.error "FamilyPvcDeterminationSubscriber error message: #{e.message}, backtrace: #{e.backtrace}"
      pvc_logger.error "FamilyPvcDeterminationSubscriber payload: #{payload} "
      ack(delivery_info.delivery_tag)
    end
  end
end
