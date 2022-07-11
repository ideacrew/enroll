# frozen_string_literal: true

module Subscribers
  # Subscriber will receive a CV3Application payload that is triggered from EA(when FA Application transitions to determined state).
  class FamilyRrvDeterminationSubscriber
    include ::EventSource::Subscriber[amqp: 'enroll.fdsh.verifications']

    subscribe(:on_enroll_fdsh_verifications) do |delivery_info, _metadata, response|
      subscriber_logger = subscriber_logger_for(:on_enroll_fdsh_verifications)
      payload = JSON.parse(response, symbolize_names: true)
      log_payload(subscriber_logger, logger, payload)

      add_fa_eligibility_determination(subscriber_logger, payload)

      ack(delivery_info.delivery_tag)
    rescue StandardError, SystemStackError => e
      log_error(subscriber_logger, logger, :on_enroll_fdsh_verifications, e)
      ack(delivery_info.delivery_tag)
    end

    private

    # Creates GroupPremiumCredits and MemberPremiumCredits for a Family with Financial Assistance Application's Eligibility Determination
    def add_fa_eligibility_determination(subscriber_logger, payload)
      result = ::Operations::Families::AddFaEligibilityDetermination.new.call(payload)
      log_info(subscriber_logger, result, 'add_fa_eligibility_determination')
    rescue StandardError => e
      log_error(subscriber_logger, nil, :add_fa_eligibility_determination, e)
    end

    def log_info(subscriber_logger, result, operation)
      if result.success?
        subscriber_logger.info "#{operation} success for family with primary hbx_id: #{result.success.primary_person.hbx_id}"
      else
        subscriber_logger.info "#{operation} failure for given payload. Failure: #{result}"
      end
    end

    def log_error(subscriber_logger, logger, name, err)
      logger.info "#{name} Error raised when processing given payload message: #{err}, backtrace: #{err.backtrace.join('\n')}" if logger.present?
      subscriber_logger.info "#{name} Error raised when processing given payload message: #{err}, backtrace: #{err.backtrace.join('\n')}"
    end

    def log_payload(subscriber_logger, logger, payload)
      logger.info '-' * 50
      subscriber_logger.info '-' * 50
      logger.info "Incoming parsed Payload: #{payload}"
      subscriber_logger.info "Incoming parsed Payload: #{payload}"
    end

    def subscriber_logger_for(event)
      Logger.new("#{Rails.root}/log/#{event}_#{TimeKeeper.date_of_record.strftime('%Y_%m_%d')}.log")
    end
  end
end
