module Subscribers
  class LegacyNotificationSubscriber
    include Acapi::Notifiers

    def self.worker_specification
      Acapi::Amqp::WorkerSpecification.new(
        :queue_name => "legacy_notification_subscriber",
        :kind => :topic,
        :routing_key => [
          "info.events.broker_role.#",
          "info.events.general_agent_profile.#",
          "info.events.employee_role.#",
          "info.events.consumer_role.#",
          "info.events.census_employee.#",
          "info.events.employer.#"
        ]
      )
    end

    def work_with_params(body, delivery_info, properties)
        headers = properties.headers || {}
        event_name = delivery_info.routing_key
        stringed_payload = headers.stringify_keys
        log("NOTICE EVENT: #{event_name} #{stringed_payload.inspect} #{body.inspect}", {:severity => 'info'})

        notice_event = event_name.split(".")[3]

        finder_mapping = ::ApplicationEventMapper.lookup_resource_mapping("acapi." + event_name)
        if finder_mapping.nil?
          notify("acapi.error.application.enroll.legacy_notification_subscriber", {
            :body => JSON.dump({
              :error => "BOGUS EVENT...could n't find resoure mapping for event #{event_name}."
            })})
          return :ack
        end
        recipient = finder_mapping.mapped_class.send(finder_mapping.search_method, stringed_payload[finder_mapping.identifier_key.to_s])
        if recipient.blank?
          notify("acapi.error.application.enroll.legacy_notification_subscriber", {
            :body => JSON.dump({
              :error => "Bad Payload...could n't find resource with #{stringed_payload[finder_mapping.identifier_key.to_s]}."
            })})
          return :ack
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
            options: headers['notice_params'],
            mpi_indicator: notice_trigger.mpi_indicator,
          }.merge(notice_trigger.notice_trigger_element_group.notice_peferences)).deliver
        end
        return :ack
    end
  end
end
