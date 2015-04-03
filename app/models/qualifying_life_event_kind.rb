class QualifyingLifeEventKind
  include Mongoid::Document
	include Mongoid::Timestamps

  Kinds = %w[add_member drop_member change_benefit terminate_benefit administrative]
  MarketKinds = %w[shop individual]

  EffectiveOnKinds = ["date_of_hire", "first_of_month"]
  OffsetKinds = [0, 30, 60]

  Reasons = [
    "initial_enrollment",
    "renewal",
    "open_enrollment",
    "lost_access_to_mec",
    "adoption",
    "foster_care",
    "birth",
    "marriage",
    "divorce",
    "location_change",
    "termination_of_benefits",
    "termination_of_employment",
    "immigration_status_change",
    "enrollment_error_or_misconduct_hbx",
    "enrollment_error_or_misconduct_issuer",
    "enrollment_error_or_misconduct_non_hbx",
    "contract_violation",
    "eligibility_change_medicaid_ineligible",
    "eligibility_change_assistance",
    "eligibility_change_employer_ineligible",
    "qualified_native_american",
    "exceptional_circumstances_natural_disaster",
    "exceptional_circumstances_medical_emergency",
    "exceptional_circumstances_system_outage",
    "exceptional_circumstances_domestic_abuse",
    "exceptional_circumstances_hardship_exemption",
    "exceptional_circumstances_civic_service",
    "exceptional_circumstances"
  ]

  field :title, type: String
  field :kind, type: String
  field :reason, type: String
  field :edi_code, type: String
  field :market_kind, type: String
  field :description, type: String
  field :pre_event_sep_in_days, type: Integer
  field :is_self_attested, type: Mongoid::Boolean
  field :post_event_sep_in_days, type: Integer
  field :ordinal_position, type: Integer

  index({kind:  1})
  index({market:  1})
  index({sep_start_date:  1})
  index({sep_end_date:  1})

  # validates :kind, 
  #           presence: true,
  #           allow_blank: false,
  #           allow_nil:   false,
  #           inclusion: {in: KINDS}

  validates :market_kind, 
            presence: true,
            allow_blank: false,
            allow_nil:   false,
            inclusion: {in: MarketKinds}

  # before_create :activate_household_sep
  # before_save :activate_household_sep


  class << self
    def shop_market_events
      Organization.hbx_profile.life_event.where("market_kind" => "shop").to_a
    end

    def individual_market_events
      Organization.hbx_profile.life_event.where("market_kind" => "individual").to_a
    end
  end

end
