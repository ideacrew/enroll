class NoticeTrigger
  include Mongoid::Document
  include Mongoid::Timestamps

  field :title, type: String
  field :resource_kind, type: String
  field :event_id, type: String
  field :template_id, type: String
  field :market_places, type: String

  embeds_one :notice_trigger_element_group
  accepts_nested_attributes_for :notice_trigger_element_group

  after_initialize :initialize_dependent_models

  def initialize_dependent_models
    build_notice_trigger_element_group if notice_trigger_element_group.nil?
  end



end
