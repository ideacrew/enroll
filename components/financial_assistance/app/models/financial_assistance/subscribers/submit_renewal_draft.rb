# frozen_string_literal: true

module FinancialAssistance
  module Subscribers
    # Subscriber to process messages to submit renewal draft application for a given input payload.
    class SubmitRenewalDraft
      include Acapi::Notifiers

      def self.worker_specification
        Acapi::Amqp::WorkerSpecification.new(
          :queue_name => 'submit_renewal_draft',
          :kind => :direct,
          :routing_key => 'info.events.assistance_application.submit_renewal_draft'
        )
      end

      def work_with_params(body, _delivery_info, _properties)
        logger = Logger.new("#{Rails.root}/log/acapi_fa_submit_renewal_draft_#{TimeKeeper.date_of_record.strftime('%Y_%m_%d')}.log")
        begin
          logger.info "SubmitRenewalDraft, response: #{body}"
          payload = JSON.parse(body, :symbolize_names => true)
          result = ::FinancialAssistance::Operations::Applications::Renew.new.call(payload)
          if result.success?
            logger.info "SubmitRenewalDraft, success: app_hbx_id: #{result.success.hbx_id}"
          else
            logger.info "SubmitRenewalDraft, failure: #{result.failure}"
          end
        rescue StandardError, SystemStackError => e
          logger.info "SubmitRenewalDraft, error body: #{body}, message: #{e.message}, backtrace: #{e.backtrace}"
        end
        :ack
      end
    end
  end
end
