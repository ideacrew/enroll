class CustomQleQuestion
  include Mongoid::Document

  embedded_in :qualifying_life_event_kind 
  embeds_many :custom_qle_answers

  field :content, type: String

end
