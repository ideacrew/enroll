# frozen_string_literal: true

module BenefitSponsors
  module Services
    class EdiService
      include Acapi::Notifiers

      def deliver(recipient:, event_object:, event_name:, edi_params: {})
        return if recipient.blank? || event_object.blank?
        begin
          send(:trigger_edi_event, recipient, event_object, event_name, edi_params)
        rescue Exception => e
          Rails.logger.error { "Could not deliver #{event_name} edi event due to #{e}" }
          raise e if Rails.env.test? # RSpec Expectation Not Met Error is getting rescued here
        end
      end

      def trigger_edi_event(recipient, event_object, event_name, edi_params)
        notify(
          "acapi.info.events.employer.#{event_name}",
          {
            :employer_id => recipient.hbx_id,
            :is_trading_partner_publishable => event_object.is_application_trading_partner_publishable?,
            :plan_year_id => edi_params[:plan_year_id],
            :event_name => event_name
          }
        )
      end
    end
  end
end