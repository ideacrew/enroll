class LifeEvent
  include Mongoid::Document
  include Mongoid::Timestamps

  embedded_in :hbx_profile

  KINDS = %w[add_member drop_member change_benefit terminate_benefit administrative]
  MARKET_KINDS = %w[shop individual]

  EFFECTIVE_ON_KINDS = ["date_of_hire", "first_of_month"]
  OFFSET_KINDS = [0, 30, 60]


  field :title, type: String
  field :kind, type: String
  field :edi_reason, type: String
  field :market_kind, type: String
  field :valid_examples, type: String
  field :invalid_examples, type: String

  field :pre_event_sep_in_days, type: Integer, default: 0
  field :post_event_sep_in_days, type: Integer

  field :coverage_effective_on_kind, type: String
  field :coverage_offset_kind, type: Integer

  field :description, type: String
  field :is_self_attested, type: Mongoid::Boolean
  


  class << self
    def shop_market_events
      Organization.hbx_profile.life_event.where("market_kind" => "shop").to_a
    end

    def individual_market_events
      Organization.hbx_profile.life_event.where("market_kind" => "individual").to_a
    end
  end

end
