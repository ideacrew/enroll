# frozen_string_literal: true

# Event Log concern for storing events
module EventLog
  extend ActiveSupport::Concern
  include GlobalID::Identification

  included do
    # EVENT_CATEGORIES = %i[
    #   hc4cc_eligibility
    #   sign_in
    #   sign_out
    #   password_change
    # ].freeze

    belongs_to :account, class_name: "User", inverse_of: :nil

    embeds_one :session_detail,
               class_name: "EventLogs::SessionDetail",
               as: :sessionable

    has_one :monitored_event,
            class_name: "EventLogs::MonitoredEvent",
            as: :monitorable,
            autosave: true

    field :subject_gid, type: String
    field :record_gid, type: String
    field :correlation_id, type: String
    field :message_id, type: String
    field :host_id, type: String
    field :trigger, type: String
    field :event_category, type: Symbol
    field :event_name, type: String
    field :event_outcome, type: String
    field :event_time, type: DateTime
    field :tags, type: Array

    index(subject_gid: 1)
    index(event_category: 1)
    index(account_id: 1)
    index(host_id: 1)
    index(trigger: 1)
    index(event_time: 1)

    scope :by_subject, ->(subject_id) { where(subject_gid: /#{subject_id}/i) }
    scope :by_event_category, ->(category) { where(event_category: category) }
    scope :by_account, ->(account_id) { where(account_id: account_id) }
    scope :by_host, ->(host_id) { where(host_id: host_id) }
    scope :by_trigger, ->(trigger) { where(trigger: trigger) }
    scope :events_during, lambda { |time_period|
      where(
        :event_time.gte => time_period.min,
        :event_time.lte => time_period.max
      )
    }

    def associated_resource
      return unless subject_gid

      @associated_resource ||= GlobalID::Locator.locate(subject_gid)
    rescue Mongoid::Errors::DocumentNotFound
      @associated_resource = nil
    end

    def persistence_model_class
      return unless associated_resource

      resolve_class_for("EventLogs::#{associated_resource.class}EventLog")
    end

    def domain_entity_class
      return unless associated_resource

      resolve_class_for("AcaEntities::EventLogs::#{associated_resource.class}EventLog")
    end

    def domain_contract_class
      return unless associated_resource

      resolve_class_for("AcaEntities::EventLogs::#{associated_resource.class}EventLogContract")
    end

    def resolve_class_for(class_name)
      Object.const_get(class_name) if defined?(class_name)
    end
  end
end
