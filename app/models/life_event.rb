class LifeEvent
  include Mongoid::Document
  include Mongoid::Timestamps
  include Mongoid::Versioning

  KINDS = %w[add_member drop_member change_location change_benefit terminate_benefit administrative]
  MARKET_KINDS = %w[shop individual]

  field :title, type: String
  field :kind, type: String
  field :edi_reason, type: String
  field :market_kind, type: String
  field :sep_in_days, type: Integer
  field :description, type: String
  field :is_self_attested, type: Mongoid::Boolean
  
end
