# frozen_string_literal: true

module Subscribers
  # Subscriber will receive request payload from EA to generate a renewal draft application
  class EnrollmentSubscriber
    include ::EventSource::Subscriber[amqp: 'enroll.individual.enrollments']

    subscribe(:on_enrollment_saved) do |delivery_info, _metadata, response|
      subscriber_logger = subscriber_logger_for(:on_enrollment_saved)
      payload = JSON.parse(response, symbolize_names: true)
      pre_process_message(subscriber_logger, payload)

      # Add subscriber operations below this line
      redetermine_family_eligibility(payload)

      ack(delivery_info.delivery_tag)
    rescue StandardError, SystemStackError => e
      subscriber_logger.info "EnrollmentSubscriber, payload: #{payload}, error message: #{e.message}, backtrace: #{e.backtrace}"
    #   logger.info "EnrollmentSubscriber: errored & acked. Backtrace: #{e.backtrace}"
      subscriber_logger.info "EnrollmentSubscriber, ack: #{payload}"
      ack(delivery_info.delivery_tag)
    end

    subscribe(:on_enroll_individual_enrollments) do |delivery_info, _metadata, response|
      subscriber_logger = subscriber_logger_for(:on_enroll_individual_enrollments)
      payload = JSON.parse(response, symbolize_names: true)

      subscriber_logger.info "EnrollmentSubscriber#on_enroll_individual_enrollments, response: #{payload}"

      ack(delivery_info.delivery_tag)
    rescue StandardError, SystemStackError => e
      subscriber_logger.info "EnrollmentSubscriber#on_enroll_individual_enrollments, payload: #{payload}, error message: #{e.message}, backtrace: #{e.backtrace}"
      subscriber_logger.info "EnrollmentSubscriber#on_enroll_individual_enrollments, ack: #{payload}"
      ack(delivery_info.delivery_tag)
    end

    def redetermine_family_eligibility(payload)
      enrollment = GlobalID::Locator.locate(payload[:gid])
      return if enrollment.shopping?

      family = enrollment.family
      assistance_year = enrollment.effective_on.year

      if HbxEnrollment::ENROLLED_AND_RENEWAL_STATUSES.include?(enrollment.aasm_state)
        application = family.active_financial_assistance_application(assistance_year)
        application&.enrolled_with(enrollment)
      end

      family.update_due_dates_on_vlp_docs_and_evidences(assistance_year)

      ::Operations::Eligibilities::BuildFamilyDetermination.new.call(family: family, effective_date: TimeKeeper.date_of_record)
    end

    private

    def pre_process_message(subscriber_logger, payload)
    #   logger.info '-' * 100 unless Rails.env.test?
      subscriber_logger.info "EnrollmentSubscriber, response: #{payload}"
    #   logger.info "EnrollmentSubscriber payload: #{payload}" unless Rails.env.test?
    end

    def subscriber_logger_for(event)
      Logger.new(
        "#{Rails.root}/log/#{event}_#{TimeKeeper.date_of_record.strftime('%Y_%m_%d')}.log"
      )
    end
  end
end
