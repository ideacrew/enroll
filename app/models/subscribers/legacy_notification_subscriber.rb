module Subscribers
  class LegacyNotificationSubscriber < ::Acapi::Subscription
    include Acapi::Notifiers

    def self.subscription_details
      [
        /acapi\.info\.events\.broker_role\..*/,
        /acapi\.info\.events\.general_agent_profile\..*/,
        /acapi\.info\.events\.employee_role\..*/,
        /acapi\.info\.events\.consumer_role\..*/,
        /acapi\.info\.events\.employer\..*/
      ]
    end

    def call(event_name, e_start, e_end, msg_id, payload)
      begin
        log("NOTICE EVENT: #{event_name} #{payload}", {:severity => 'info'})

        notice_event = event_name.split(".")[4]

        finder_mapping = ::ApplicationEventMapper.lookup_resource_mapping(event_name)
        if finder_mapping.nil?
          notify("acapi.error.application.enroll.remote_listener.legacy_notification_subscriber", {
            :body => JSON.dump({
              :error => "BOGUS EVENT...could n't find resoure mapping for event #{event_name}."
            })})
          return
        end
        recipient = finder_mapping.mapped_class.send(finder_mapping.search_method, payload[finder_mapping.identifier_key.to_s])
        if recipient.blank?
          notify("acapi.error.application.enroll.remote_listener.legacy_notification_subscriber", {
            :body => JSON.dump({
              :error => "Bad Payload...could n't find resource with #{payload[finder_mapping.identifier_key.to_s]}."
            })})
          return
        end

        resource_hash = {:employee => "employee_role", :employer => "employer", :broker_agency => "broker_role", :consumer_role => "consumer_role", :broker => "broker_role", :general_agency => "general_agent_profile", :census_employee => "employee_role"}
        resource   = ::ApplicationEventMapper.map_resource(recipient.class)
        event_kind = ::ApplicationEventKind.where(event_name: notice_event, resource_name: resource_hash[resource.resource_name]).first
        recipient = recipient.class.to_s == "EmployeeRole" ? recipient.census_employee : recipient

        if event_kind.present?
          notice_trigger = event_kind.notice_triggers.first

          builder = notice_trigger.notice_builder.camelize.constantize.new(recipient, {
            template: notice_trigger.notice_template,
            subject: event_kind.title,
            event_name: notice_event,
            options: payload['notice_params'],
            mpi_indicator: notice_trigger.mpi_indicator,
          }.merge(notice_trigger.notice_trigger_element_group.notice_peferences)).deliver
        end

      rescue Exception => e
        notify("acapi.error.application.enroll.remote_listener.legacy_notification_subscriber", {
          :body => JSON.dump({
            :error => e.inspect,
            :message => e.message,
            :backtrace => e.backtrace
          })})
      end
    end
  end
end
