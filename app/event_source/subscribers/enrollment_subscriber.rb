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

    subscribe(:on_coverage_selected) do |delivery_info, _metadata, response|
      subscriber_logger = subscriber_logger_for(:on_coverage_selected)
      payload = JSON.parse(response, symbolize_names: true)
      pre_process_message(subscriber_logger, payload)

      # Add subscriber operations below this line
      create_grants(payload)

      ack(delivery_info.delivery_tag)
    rescue StandardError, SystemStackError => e
      subscriber_logger.info "EnrollmentSubscriber, payload: #{payload}, error message: #{e.message}, backtrace: #{e.backtrace}"
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

    def create_grants(payload)
      enrollment = GlobalID::Locator.locate(payload[:enrollment_global_id])

      title = 'OSSE ChildCare Subsidy Premium'
      key = :osse_subsidy


      enrollment.hbx_enrollment_members.each do |hbx_enrollment_member|
        next if enrollment.is_shop? && !hbx_enrollment_member.is_subscriber?

        value = {
          title: title,
          key: key,
          value: enrollment.osse_subsidy_for_member(hbx_enrollment_member)
        }

        grant_values = {
          title: title,
          key: key,
          start_on: enrollment.effective_on,
          value: value
        }
        eligibility = eligibility(hbx_enrollment_member)

        eligibility.persist_grants(grant_values)

      end
    end

    def eligibility(hbx_enrollment_member)
      enrollment = hbx_enrollment_member.hbx_enrollment
      person = hbx_enrollment_member.person

      subject =
        if enrollment.is_shop?
          enrollment.employee_role
        elsif enrollment.is_coverall?
          person.resident_role
        else
          person.consumer_role
        end

      subject.eligibilities.max_by(&:created_at)
    end

    def redetermine_family_eligibility(payload)
      enrollment = GlobalID::Locator.locate(payload[:gid])
      return if enrollment.shopping? || Rails.env.test?

      family = enrollment.family
      assistance_year = enrollment.effective_on.year

      if HbxEnrollment::ENROLLED_AND_RENEWAL_STATUSES.include?(enrollment.aasm_state)
        family.fail_negative_and_pending_verifications
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
