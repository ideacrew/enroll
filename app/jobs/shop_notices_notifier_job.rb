class ShopNoticesNotifierJob < ActiveJob::Base
  queue_as :default

  def perform(id, event)
    Resque.logger.level = Logger::DEBUG
    id = "5951291db79d5014c200000a"
    profile = EmployerProfile.find(id) || CensusEmployee.where(id: id).first
    event_kind = ApplicationEventKind.where(:event_name => "initial_employer_approval").first
    notice_trigger = event_kind.notice_triggers.first
    builder = notice_trigger.notice_builder.camelize.constantize.new(profile, {
              template: notice_trigger.notice_template,
              subject: event_kind.title,
              mpi_indicator: notice_trigger.mpi_indicator,
              event_name: "initial_employer_approval",
              }.merge(notice_trigger.notice_trigger_element_group.notice_peferences)).deliver 
  end
end