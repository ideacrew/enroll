class IvlNoticesNotifierJob < ActiveJob::Base
  include Acapi::Notifiers

  queue_as :default

  def perform(person_id, event, options = {})
    Resque.logger.level = Logger::DEBUG
    person = Person.find(person_id)
    role = person.consumer_role || person.resident_role
    event_kind = ApplicationEventKind.where(:event_name => event).first
    notice_trigger = event_kind.notice_triggers.first
    notice_class(notice_trigger.notice_builder).new(role, {
      template: notice_trigger.notice_template,
      subject: event_kind.title,
      event_name: event,
      options: options,
      mpi_indicator: notice_trigger.mpi_indicator
    }.merge(notice_trigger.notice_trigger_element_group.notice_peferences)).deliver
  rescue StandardError => e
    log("Could not generate IVL open enrollment notice event #{event} due to #{e} for Person: #{person_id}\n#{e.backtrace.join("\n")}")
    raise e
  end

  def notice_class(notice_type)
    notice_class = ['IvlNotice',
                    'Notice',
                    'IvlNotices::ConditionalEligibilityNoticeBuilder',
                    'IvlNotices::CoverallToIvlTransitionNoticeBuilder',
                    'IvlNotices::DocumentsVerification',
                    'IvlNotices::EligibilityDenialNoticeBuilder',
                    'IvlNotices::EligibilityNoticeBuilder',
                    'IvlNotices::EnrollmentNoticeBuilder',
                    'IvlNotices::EnrollmentNoticeBuilderWithDateRange',
                    'IvlNotices::FinalCatastrophicPlanNotice',
                    'IvlNotices::IneligibilityNoticeBuilder',
                    'IvlNotices::IvlBacklogVerificationNoticeUqhp',
                    'IvlNotices::IvlRenewalNotice',
                    'IvlNotices::IvlTaxNotice',
                    'IvlNotices::IvlToCoverallTransitionNoticeBuilder',
                    'IvlNotices::IvlVtaNotice',
                    'IvlNotices::NoAppealVariableIvlRenewalNotice',
                    'IvlNotices::NoticeBuilder',
                    'IvlNotices::ReminderNotice',
                    'RenewalNotice',
                    'IvlNotices::SecondIvlRenewalNotice',
                    'IvlNotices::VariableIvlRenewalNotice'].find { |x| x == notice_type.classify }
    raise "Unable to find the notice_class" if notice_class.nil?
    notice_class.camelize.constantize
  end
end