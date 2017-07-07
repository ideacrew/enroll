class ShopNoticesNotifierJob < ActiveJob::Base
  queue_as :default

  def perform(id, event)
    Resque.logger.level = Logger::DEBUG
    profile = EmployerProfile.find(id) || CensusEmployee.where(id: id).first
    event_kind = ApplicationEventKind.where(:event_name => "initial_employer_final_reminder_to_publish_plan_year").first
    notice_trigger = event_kind.notice_triggers.first
    builder = notice_trigger.notice_builder.camelize.constantize.new(profile, {
              template: notice_trigger.notice_template,
              subject: event_kind.title,
              event_name: event_name: event,
              mpi_indicator: notice_trigger.mpi_indicator,
              }.merge(notice_trigger.notice_trigger_element_group.notice_peferences)).deliver
  end
end