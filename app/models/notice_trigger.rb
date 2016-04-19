class NoticeTrigger
  include Mongoid::Document
  include Mongoid::Timestamps

  field :name, type: String
  field :notice_template, type: String
  field :notice_builder, type: String

  embedded_in :application_event_kind

  embeds_one :notice_trigger_element_group
  accepts_nested_attributes_for :notice_trigger_element_group

  after_initialize :initialize_dependent_models

  def publish(new_event)
    rule = EventForNoticeTriggerRule.new(self, new_event)
    if rule.satisfied?
      notice_builder.camelize.constantize.new(self, template: notice_template)
      # call notice generation code
    else
      # log error
    end
  end


private
  def initialize_dependent_models
    build_notice_trigger_element_group if notice_trigger_element_group.nil?
  end
end
