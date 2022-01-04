# frozen_string_literal: true

module Subscribers
  # Subscriber will receive request payload from EA to generate a renewal draft application
  class AptcCsrCreditEligibilitiesSubscriber
    include ::EventSource::Subscriber[amqp: 'enroll.individual.eligibilities']

    subscribe(
      :on_enroll_individual_eligibilities
    ) do |delivery_info, _metadata, response|
      logger.info '-' * 100 unless Rails.env.test?

      payload = JSON.parse(response, symbolize_names: true)

      subscriber_logger =
        Logger.new(
          "#{Rails.root}/log/on_individual_eligibilities_#{TimeKeeper.date_of_record.strftime('%Y_%m_%d')}.log"
        )

      subscriber_logger.info "AptcCsrCreditEligibilitiesSubscriber, response: #{payload}"
      logger.info "AptcCsrCreditEligibilitiesSubscriber payload: #{payload}" unless Rails.env.test?

      evidence = GlobalID::Locator.locate(payload[:gid])
      applicant = evidence._parent
      application = applicant.application

      result = ::Operations::Eligibilities::BuildFamilyDetermination.new.call(family: application.family, effective_date: Date.new(2022,1,1))

      if result.success?
        logger.info "AptcCsrCreditEligibilitiesSubscriber: acked with success: #{result.success}"
        subscriber_logger.info "AptcCsrCreditEligibilitiesSubscriber: acked with success: #{result.success}"
      else
        errors =
          if result.failure.is_a?(Dry::Validation::Result)
            result.failure.errors.to_h
          else
            result.failure
          end

        logger.info "AptcCsrCreditEligibilitiesSubscriber: acked with failure, errors: #{errors}"
        subscriber_logger.info "AptcCsrCreditEligibilitiesSubscriber: acked with failure, errors: #{errors}"
      end

      ack(delivery_info.delivery_tag)
    rescue StandardError, SystemStackError => e
      subscriber_logger.info "AptcCsrCreditEligibilitiesSubscriber, payload: #{payload}, error message: #{e.message}, backtrace: #{e.backtrace}"
      logger.info "AptcCsrCreditEligibilitiesSubscriber: errored & acked. Backtrace: #{e.backtrace}"
      subscriber_logger.info "AptcCsrCreditEligibilitiesSubscriber, ack: #{payload}"
      ack(delivery_info.delivery_tag)
    end
  end
end
