class CustomQleQuestion
  include Mongoid::Document

  embedded_in :qualifying_life_event_kind 

  field :question, type: String
  field :answers, type: Array, default: []

end
