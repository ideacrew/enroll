# frozen_string_literal: true

module Subscribers
  module Eligible
    # Subscriber will receive Enterprise requests like date change
    class EligibilitySubscriber
      include ::EventSource::Subscriber[
                amqp: "enroll.eligible.eligibility.events"
              ]

      subscribe(
        :on_create_default_eligibility
      ) do |delivery_info, _metadata, response|
        logger_name =
          "on_create_default_eligibility_#{TimeKeeper.date_of_record.strftime('%Y_%m_%d')}"
        subscriber_logger = Logger.new("#{Rails.root}/log/#{logger_name}.log")
        subscriber_logger.info "-" * 100 unless Rails.env.test?

        payload = JSON.parse(response, symbolize_names: true)
        subscriber_logger.info "EligibilitySubscriber, payload: #{payload}"

        subject = GlobalID::Locator.locate(payload[:subject_gid])
        eligibility_date = TimeKeeper.date_of_record
        effective_date = payload[:effective_date].to_date
        evidence_key = payload[:evidence_key].to_sym

        eligibility = subject.eligibility_on(eligibility_date)
        unless eligibility
          result =
            create_eligibility(
              {
                subject: subject,
                evidence_key: evidence_key,
                evidence_value: "false",
                effective_date: effective_date
              }
            )

          subscriber_logger.error "EligibilitySubscriber, payload: #{payload}. Failed due to #{result.failure}" unless result.success?
        end
        ack(delivery_info.delivery_tag)
      rescue StandardError, SystemStackError => e
        subscriber_logger.error "EligibilitySubscriber, payload: #{payload}, error message: #{e.message}, backtrace: #{e.backtrace}"
        ack(delivery_info.delivery_tag)
      end

      subscribe(:on_renew_eligibility) do |delivery_info, _metadata, response|
        logger_name =
          "on_renew_eligibility_#{TimeKeeper.date_of_record.strftime('%Y_%m_%d')}"
        subscriber_logger = Logger.new("#{Rails.root}/log/#{logger_name}.log")
        subscriber_logger.info "-" * 100 unless Rails.env.test?

        payload = JSON.parse(response, symbolize_names: true)
        subscriber_logger.info "EligibilitySubscriber#on_enroll_enterprise_events, response: #{payload}"

        subject = GlobalID::Locator.locate(payload[:subject_gid])
        eligibility_date = TimeKeeper.date_of_record
        effective_date = payload[:effective_date].to_date
        evidence_key = payload[:evidence_key].to_sym

        eligibility = subject.eligibility_on(eligibility_date)
        osse_eligibility = eligibility.blank? ? false : eligibility.is_eligible_on?(eligibility_date)

        renewal_eligibility = subject.eligibility_on(effective_date)
        unless renewal_eligibility
          result =
            create_eligibility(
              {
                subject: subject,
                evidence_key: evidence_key,
                evidence_value: osse_eligibility.to_s,
                effective_date: effective_date
              }
            )

          subscriber_logger.error "EligibilitySubscriber, payload: #{payload}. Failed due to #{result.failure}" unless result.success?
        end

        ack(delivery_info.delivery_tag)
      rescue StandardError, SystemStackError => e
        subscriber_logger.error "EligibilitySubscriber#on_enroll_enterprise_events, payload: #{payload}, error message: #{e.message}, backtrace: #{e.backtrace}"
        ack(delivery_info.delivery_tag)
      end

      private

      def eligibility_operation_for(subject)
        case subject.class.to_s
        when "ConsumerRole", "ResidentRole"
          ::Operations::IvlOsseEligibilities::CreateIvlOsseEligibility
        when "BenefitSponsors::BenefitSponsorships::BenefitSponsorship"
          ::BenefitSponsors::Operations::BenefitSponsorships::ShopOsseEligibilities::CreateShopOsseEligibility
        end
      end

      def create_eligibility(options)
        operation = eligibility_operation_for(options[:subject]).new
        operation.default_eligibility = true if options[:evidence_value] == "false"
        operation.prospective_eligibility = true
        operation.call(
          {
            subject: options[:subject].to_global_id,
            evidence_key: options[:evidence_key],
            evidence_value: options[:evidence_value],
            effective_date: options[:effective_date]
          }
        )
      end
    end
  end
end
