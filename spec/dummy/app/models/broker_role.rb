class BrokerRole
  include Mongoid::Document
  include Mongoid::Timestamps

  PROVIDER_KINDS = %W[broker assister]
  BROKER_UPDATED_EVENT_NAME = "acapi.info.events.broker.updated"

  MARKET_KINDS_OPTIONS = {
    "Individual & Family Marketplace ONLY" => "individual",
    "Small Business Marketplace ONLY" => "shop",
    "Both – Individual & Family AND Small Business Marketplaces" => "both"
  }

  BROKER_CARRIER_APPOINTMENTS = {"Aetna Health Inc" => nil,
    "Aetna Life Insurance Company" => nil,
     "Carefirst Bluechoice Inc" => nil,
     "Group Hospitalization and Medical Services Inc" => nil,
     "Kaiser Foundation" => nil,
     "Optimum Choice" => nil,
     "United Health Care Insurance" => nil,
     "United Health Care Mid Atlantic" => nil}

  embedded_in :person

  field :aasm_state, type: String

  # Broker National Producer Number (unique identifier)
  field :npn, type: String
  field :broker_agency_profile_id, type: BSON::ObjectId
  field :provider_kind, type: String
  field :reason, type: String

  field :market_kind, type: String
  field :languages_spoken, type: Array, default: ["en"]
  field :working_hours, type: Boolean, default: false
  field :accept_new_clients, type: Boolean
  field :license, type: Boolean
  field :training, type: Boolean
  field :carrier_appointments, type: Hash , default: BROKER_CARRIER_APPOINTMENTS

  class << self
    def find(id)
      return nil if id.blank?
      people = Person.where("broker_role._id" => BSON::ObjectId.from_string(id))
      people.any? ? people[0].broker_role : nil
    end
  end
end
