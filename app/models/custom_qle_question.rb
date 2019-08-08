class CustomQleQuestion
  include Mongoid::Document

  embedded_in :qualifying_life_event_kind 
  embeds_one :custom_qle_answer

  field :title, type: String
  field :content, type: String
  field :type, type: String

  accepts_nested_attributes_for :custom_qle_answer
end
