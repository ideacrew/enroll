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

  field :npn, type: String
  field :broker_agency_profile_id, type: BSON::ObjectId
  field :benefit_sponsors_broker_agency_profile_id, type: BSON::ObjectId
  field :provider_kind, type: String
  field :reason, type: String

  field :market_kind, type: String
  field :languages_spoken, type: Array, default: ["en"]
  field :working_hours, type: Boolean, default: false
  field :accept_new_clients, type: Boolean

  validates_presence_of :npn, :provider_kind

  validates :npn,
    numericality: {only_integer: true},
    length: { minimum: 1, maximum: 10 },
    uniqueness: true,
    allow_blank: false

  validates :provider_kind,
    allow_blank: false,
    inclusion: { in: PROVIDER_KINDS, message: "%{value} is not a valid provider kind" }

  def broker_agency_profile=(new_broker_agency)
    if new_broker_agency.nil?
      self.benefit_sponsors_broker_agency_profile_id = nil
    else
      raise ArgumentError.new("expected BenefitSponsors::Organizations::BrokerAgencyProfile class") unless new_broker_agency.is_a? BenefitSponsors::Organizations::BrokerAgencyProfile
      self.benefit_sponsors_broker_agency_profile_id = new_broker_agency._id
      @broker_agency_profile = new_broker_agency
    end
  end

  def broker_agency_profile
    return @broker_agency_profile if defined? @broker_agency_profile
    @broker_agency_profile = BenefitSponsors::Organizations::Organization.where(:"profiles._id" => broker_agency_profile_id).first.broker_agency_profile if has_broker_agency_profile?
  end

end