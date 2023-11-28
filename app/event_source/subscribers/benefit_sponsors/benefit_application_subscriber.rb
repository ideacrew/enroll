# frozen_string_literal: true

module Subscribers
  module BenefitSponsors
    # Subscriber will receive payload from EA for events related to benefit application
    class BenefitApplicationSubscriber
      include ::EventSource::Subscriber[amqp: 'enroll.benefit_sponsors.benefit_application']

      subscribe(:on_open_enrollment_began) do |delivery_info, _metadata, response|
        logger.info '-' * 100
        payload = JSON.parse(response, :symbolize_names => true)
        benefit_application = GlobalID::Locator.locate(payload[:application_global_id])
        benefit_sponsorship = benefit_application.benefit_sponsorship

        subscriber_logger.info "on_open_enrollment_began, employer: #{benefit_sponsorship.legal_name} fein: #{benefit_sponsorship.fein}"
        subscriber_logger.info "BenefitApplicationsSubscriber on_open_enrollment_began payload: #{payload}"
        logger.info "BenefitApplicationsSubscriber on_open_enrollment_began payload: #{payload}"

        ack(delivery_info.delivery_tag)
      rescue StandardError, SystemStackError => e
        subscriber_logger.error "BenefitApplicationsSubscriber, employer fein: #{benefit_sponsorship.fein}, error message: #{e.message}, backtrace: #{e.backtrace}"
        logger.error "BenefitApplicationsSubscriber: errored & acked. payload: #{payload} error message: #{e.message}, backtrace: #{e.backtrace}"
        ack(delivery_info.delivery_tag)
      end

      private

      def subscriber_logger
        return @subscriber_logger if defined? @subscriber_logger
        @subscriber_logger = Logger.new("#{Rails.root}/log/on_open_enrollment_began_#{TimeKeeper.date_of_record.strftime('%Y_%m_%d')}.log")
      end
    end
  end
end
