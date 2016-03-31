class NoticeTrigger
  include Mongoid::Document
  include Mongoid::Timestamps

  MARKET_PLACE_KINDS  = %w(individual shop)

  field :hbx_id, type: Integer
  field :title, type: String
  field :market_places, type: Array
  field :resource_publisher, type: String
  field :notice_template_id, type: BSON::ObjectId

  embedded_in :application_event

  embeds_one :notice_trigger_element_group
  accepts_nested_attributes_for :notice_trigger_element_group

  after_initialize :initialize_dependent_models

  def publish(new_event)
    rule = EventForNoticeTriggerRule.new(self, new_event)
    if rule.satisfied?
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
