# frozen_string_literal: true

module Subscribers
  # Subscriber will receive a CV3Application payload that is triggered from EA(when FA Application transitions to determined state).
  class ApplicationDeterminedSubscriber
    include ::EventSource::Subscriber[amqp: 'enroll.fdsh.verifications']

    subscribe(:on_magi_medicaid_application_determined) do |delivery_info, _metadata, response|
      subscriber_logger = subscriber_logger_for(:on_magi_medicaid_application_determined)
      payload = JSON.parse(response, symbolize_names: true)
      log_payload(subscriber_logger, logger, payload)

      # Moving this to aasm state after event.
      # create_tax_household_group(subscriber_logger, payload) if !Rails.env.test? && EnrollRegistry.feature_enabled?(:temporary_configuration_enable_multi_tax_household_feature)
      # generate_enrollments(subscriber_logger, payload) if !Rails.env.test? && EnrollRegistry.feature_enabled?(:temporary_configuration_enable_multi_tax_household_feature)

      ack(delivery_info.delivery_tag)
    rescue StandardError, SystemStackError => e
      log_error(subscriber_logger, logger, :on_magi_medicaid_application_determined, e)
      ack(delivery_info.delivery_tag)
    end

    private

    # Creates tax_household_groups and its accociations for a Family with Financial Assistance Application's Eligibility Determination
    def create_tax_household_group(subscriber_logger, payload)
      result = ::Operations::Families::CreateTaxHouseholdGroupOnFaDetermination.new.call(payload)
      log_info(subscriber_logger, result, 'create_tax_household_group_on_fa_determination')
      if result.success?
        family = result.success.family
        ::Operations::Eligibilities::BuildFamilyDetermination.new.call(family: family, effective_date: TimeKeeper.date_of_record)
      end
    rescue StandardError => e
      log_error(subscriber_logger, nil, :create_tax_household_group_on_fa_determination, e)
    end

    def generate_enrollments(subscriber_logger, payload)
      return unless EnrollRegistry.feature_enabled?(:apply_aggregate_to_enrollment)
      family_hbx_id = payload[:family_reference][:hbx_id]
      families = Family.where(hbx_assigned_id: family_hbx_id)

      unless families.count == 1
        subscriber_logger.info "generate_enrollments failed to find a family, payload: #{payload}"
        return
      end

      family = families.first

      Operations::Individual::OnNewDetermination.new.call({family: family, year: payload[:assistance_year]})
    end

    def log_info(subscriber_logger, result, operation)
      if result.success?
        subscriber_logger.info "#{operation} success for family with hbx_id: #{result.success.family.hbx_assigned_id}"
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