# frozen_string_literal: true

module Services
  class IvlEnrollmentService

    def initialize
      @logger = Logger.new("#{Rails.root}/log/family_advance_day_#{TimeKeeper.date_of_record.strftime('%Y_%m_%d')}.log")
    end

    def process_enrollments(new_date)
      expire_individual_market_enrollments
      begin_coverage_for_ivl_enrollments if new_date == new_date.beginning_of_year
      # Deprecate following methods when DC moved to new eligibilities model
      send_enr_or_dr_notice_to_ivl(new_date)
      send_reminder_notices_for_ivl(new_date)
    end

    def expire_individual_market_enrollments
      @logger.info "Started expire_individual_market_enrollments process at #{TimeKeeper.datetime_of_record.to_s}"
      current_benefit_period = HbxProfile.current_hbx.benefit_sponsorship.current_benefit_coverage_period
      batch_size = 500
      offset = 0
      individual_market_enrollments = HbxEnrollment.where(
        :effective_on.lt => current_benefit_period.start_on,
        :kind.in => ["individual", "coverall"],
        :aasm_state.in => HbxEnrollment::ENROLLED_STATUSES - ["coverage_termination_pending"]
      )
      while offset <= individual_market_enrollments.count
        individual_market_enrollments.offset(offset).limit(batch_size).no_timeout.each do |enrollment|
          enrollment.expire_coverage! if enrollment.may_expire_coverage?
          @logger.info "Processed enrollment: #{enrollment.hbx_id}"
        rescue StandardError => e
          @logger.info "Unable to expire enrollment#{enrollment.id}, error: #{e.backtrace}"
        end
        offset += batch_size
      end
      @logger.info "Ended expire_individual_market_enrollments process at #{TimeKeeper.datetime_of_record}"
    end

    def begin_coverage_for_ivl_enrollments
      @logger.info "Started begin_coverage_for_ivl_enrollments process at #{TimeKeeper.datetime_of_record.to_s}"
      current_benefit_period = HbxProfile.current_hbx.benefit_sponsorship.current_benefit_coverage_period
      batch_size = 500
      offset = 0
      ivl_enrollments = HbxEnrollment.where(
        :effective_on => { "$gte" => current_benefit_period.start_on, "$lt" => current_benefit_period.end_on },
        :kind.in => ["individual", "coverall"],
        :aasm_state.in => ["auto_renewing", "renewing_coverage_selected"]
      )
      @logger.info "Total IVL auto renewing enrollment count: #{ivl_enrollments.count}"
      count = 0
      while offset <= ivl_enrollments.count
        ivl_enrollments.offset(offset).limit(batch_size).no_timeout.each do |enrollment|
          if enrollment.may_begin_coverage?
            enrollment.begin_coverage!
            count += 1
            @logger.info "Processed enrollment: #{enrollment.hbx_id}"
          end
        rescue StandardError => e
          @logger.info "Unable to begin coverage for #{enrollment.id}, error: #{e.backtrace}"
        end
        offset += batch_size
      end
      @logger.info "Total IVL auto renewing enrollment processed count: #{count}"
      @logger.info "Ended begin_coverage_for_ivl_enrollments process at #{TimeKeeper.datetime_of_record.to_s}"
    end

    def enrollment_notice_for_ivl_families(new_date)
      start_time = (new_date - 2.days).in_time_zone("Eastern Time (US & Canada)").beginning_of_day
      end_time = (new_date - 2.days).in_time_zone("Eastern Time (US & Canada)").end_of_day
      Family.where(
        :"_id".in => HbxEnrollment.where(
          kind: "individual",
          :"aasm_state".in => HbxEnrollment::ENROLLED_STATUSES,
          created_at: { "$gte" => start_time, "$lte" => end_time}
        ).pluck(:family_id)
      )
    end

    # Triggers ENR or DR notice based on the application setting
    def send_enr_or_dr_notice_to_ivl(new_date)
      @logger.info '*' * 50
      @logger.info "Started send_enr_or_dr_notice_for_ivl process at #{TimeKeeper.datetime_of_record}"
      families = enrollment_notice_for_ivl_families(new_date)
      families.each do |family|
        begin
          person = family.primary_applicant.person
          if EnrollRegistry[:legacy_enrollment_trigger].enabled?
            IvlNoticesNotifierJob.perform_later(person.id.to_s, "enrollment_notice") if person.consumer_role.present?
          end
        rescue Exception => e
          Rails.logger.error { "Unable to deliver enrollment notice #{person.hbx_id} due to #{e.inspect}" }
        end
      end
      @logger.info "Ended send_enr_or_dr_notice_for_ivl process at #{TimeKeeper.datetime_of_record}"
      families
    end

    def trigger_enrollment_notice(enrollment)
      ::Operations::Notices::IvlEnrNoticeTrigger.new.call(enrollment: enrollment) unless Rails.env.test?
    rescue StandardError => e
      Rails.logger.error { "Unable to trigger enrollment notice for person with enrollment hbx_id #{enrollment.hbx_id} due to #{e.inspect}" }
    end

    def trigger_reminder_notices(family, event_name)
      person = family.primary_person
      if EnrollRegistry[:legacy_enrollment_trigger].enabled?
        if event_name.present?
          IvlNoticesNotifierJob.perform_later(person.id.to_s, event_name)
          @logger.info "Sent #{event_name} to #{person.hbx_id}" unless Rails.env.test?
        end
      end
    rescue StandardError => e
      @logger.info "Unable to trigger document reminder notice for hbx_id: #{person.hbx_id} due to #{e.inspect}"
    end

    def reminder_notice_logger(result, person, event_name)
      return if Rails.env.test?

      if result.success?
        @logger.info "Sent DR notice event: #{event_name} to #{person.hbx_id}"
      else
        @logger.info "Failed to send DR notice event: #{event_name} to #{person.hbx_id}"
      end
    end

    def event_name(family, date)
      case (family.best_verification_due_date.to_date.mjd - date.mjd)
      when 85
        "first_verifications_reminder"
      when 70
        "second_verifications_reminder"
      when 45
        "third_verifications_reminder"
      when 30
        "fourth_verifications_reminder"
      end
    end

    def send_reminder_notices_for_ivl(date)
      families =
        if EnrollRegistry.feature_enabled?(:include_faa_outstanding_verifications)
          Family.outstanding_verifications_including_faa_datatable
        else
          Family.outstanding_verification_datatable
        end
      return if families.blank?

      @logger.info '*' * 50
      @logger.info "Started send_reminder_notices_for_ivl process at #{TimeKeeper.datetime_of_record}"

      families.each do |family|
        begin
          next if EnrollRegistry.feature_enabled?(:skip_aptc_families_from_document_reminder_notices) && family.has_valid_e_case_id? #skip assisted families
          consumer_role = family.primary_applicant.person.consumer_role
          person = family.primary_applicant.person
          if consumer_role.present? && family.best_verification_due_date.present? && (family.best_verification_due_date > date)
            event_name = event_name(family, date)
            trigger_reminder_notices(family, event_name)
          end
        rescue StandardError => e
          @logger.info "Unable to send verification reminder notices to #{family.primary_person&.hbx_id} due to #{e}"
        end
      end
      @logger.info "End of generating reminder notices at #{TimeKeeper.datetime_of_record}"
    end
  end
end
