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

    def redetermine_family_eligibility(payload)
      enrollment = GlobalID::Locator.locate(payload[:gid])
      return if enrollment.shopping?

      if HbxEnrollment::ENROLLED_AND_RENEWAL_STATUSES.include?(enrollment.aasm_state)
        family = enrollment.family
        application = family.active_financial_assistance_application(enrollment.effective_on.year)
        application&.enrolled_with(enrollment)
      end
      update_due_date_on_vlp_documents(family)

      ::Operations::Eligibilities::BuildFamilyDetermination.new.call(
        family: enrollment.family,
        effective_date: TimeKeeper.date_of_record
      )
    end

    private

    def update_due_date_on_vlp_documents(family)
      ::Operations::People::UpdateDueDateOnVlpDocuments.new.call(family: family, due_date: TimeKeeper.date_of_record + 95.days)
    end

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
