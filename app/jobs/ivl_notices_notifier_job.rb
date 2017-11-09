class IvlNoticesNotifierJob < ActiveJob::Base
  queue_as :default

  def perform(consumer_role, event)
    Resque.logger.level = Logger::DEBUG
    event_kind = ApplicationEventKind.where(:event_name => event).first
    notice_trigger = event_kind.notice_triggers.first
    builder = notice_trigger.notice_builder.camelize.constantize.new(consumer_role, {
              template: notice_trigger.notice_template,
              subject: event_kind.title,
              event_name: event,
              mpi_indicator: notice_trigger.mpi_indicator,
              }.merge(notice_trigger.notice_trigger_element_group.notice_peferences)).deliver

  end
end