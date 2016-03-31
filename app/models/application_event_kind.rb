class ApplicationEventKind
  include Mongoid::Document

  # PERSON_CREATED_EVENT_NAME = "acapi.info.events.individual.created"

  EVENT_PREFIX = "acapi.info.events."
  RESOURCE_NAME_KINDS = %w(
                          family 
                          employer_profile 
                          employee_role 
                          consumer_role 
                          broker_agency_profile 
                          broker_role 
                          issuer_profile 
                          general_agent_profile
                        )

  field :hbx_id, type: Integer
  field :title, type: String
  field :description, type: String
  field :resource_name, type: String
  field :event_name, type: String
  field :key, type: String

  embeds_many :notice_triggers
  accepts_nested_attributes_for :notice_triggers

  validates_presence_of :title, :resource_name, :event_name
  validates :resource_name,
    inclusion: { in: RESOURCE_NAME_KINDS, message: "%{value} is not a valid resource name" }

  def resource_name=(new_resource_name)
    write_attribute(:resource_name, stringify(new_resource_name))
    update_key
  end

  def event_name=(new_event_name)
    write_attribute(:event_name, stringify(new_event_name))
    update_key
  end

  def resource_events
    resource_name.camelize.constantize
  end

private
  def update_key
    if resource_name.present? && event_name.present?
      write_attribute(:key, [resource_name, event_name].compact.join("."))
    end
  end

  def stringify(value)
    case value
    when Symbol
      value.to_s
    when String
      value.downcase
    else
      # assume this is a class instance
      value.underscore
    end
  end

end

