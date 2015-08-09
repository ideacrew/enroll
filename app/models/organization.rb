class Organization
  include Mongoid::Document
  include Mongoid::Timestamps
  include Mongoid::Versioning

  extend Mongorder

  ENTITY_KINDS = [
    "tax_exempt_organization",
    "c_corporation",
    "s_corporation",
    "partnership",
    "limited_liability_corporation",
    "limited_liability_partnership",
    "household_employer",
    "governmental_employer",
    "foreign_embassy_or_consulate"
  ]

  auto_increment :hbx_id, type: Integer

  # Registered legal name
  field :legal_name, type: String

  # Doing Business As (alternate name)
  field :dba, type: String

  # Federal Employer ID Number
  field :fein, type: String

  # Web URL
  field :home_page, type: String

  field :is_active, type: Boolean

  # User or Person ID who created/updated
  field :updated_by, type: BSON::ObjectId

  default_scope -> {order("legal_name ASC")}

  embeds_many :office_locations, cascade_callbacks: true, validate: true

  embeds_one :employer_profile, cascade_callbacks: true, validate: true
  embeds_one :broker_agency_profile, cascade_callbacks: true, validate: true
  embeds_one :carrier_profile, cascade_callbacks: true, validate: true
  embeds_one :hbx_profile, cascade_callbacks: true, validate: true

  accepts_nested_attributes_for :office_locations, :employer_profile, :broker_agency_profile, :carrier_profile, :hbx_profile

  validates_presence_of :legal_name, :fein, :office_locations #, :updated_by

  validates :fein,
    length: { is: 9, message: "%{value} is not a valid FEIN" },
    numericality: true,
    uniqueness: true
    
  validate :office_location_kinds
    


  index({ hbx_id: 1 }, { unique: true })
  index({ legal_name: 1 })
  index({ dba: 1 }, {sparse: true})
  index({ fein: 1 }, { unique: true })
  index({ is_active: 1 })

  # CarrierProfile child model indexes
  index({"carrier_profile._id" => 1}, { unique: true, sparse: true })

  # BrokerAgencyProfile child model indexes
  index({"broker_agency_profile._id" => 1}, { unique: true, sparse: true })
  index({"broker_agency_profile.aasm_state" => 1})
  index({"broker_agency_profile.primary_broker_role_id" => 1}, { unique: true, sparse: true })
  index({"broker_agency_profile.market_kind" => 1})

  # EmployerProfile child model indexes
  index({"employer_profile._id" => 1}, { unique: true, sparse: true })
  index({"employer_profile.aasm_state" => 1})

  index({"employer_profile.plan_years._id" => 1}, { unique: true, sparse: true })
  index({"employer_profile.plan_years.aasm_state" => 1})
  index({"employer_profile.plan_years.start_on" => 1})
  index({"employer_profile.plan_years.end_on" => 1})
  index({"employer_profile.plan_years.open_enrollment_start_on" => 1})
  index({"employer_profile.plan_years.open_enrollment_end_on" => 1})
  index({"employer_profile.plan_years.benefit_groups._id" => 1})
  index({"employer_profile.plan_years.benefit_groups.reference_plan_id" => 1})

  index({"employer_profile.workflow_state_transitions.transition_at" => 1,
         "employer_profile.workflow_state_transitions.to_state" => 1},
         { name: "employer_profile_workflow_to_state" })

  index({"employer_profile.broker_agency_accounts._id" => 1})
  index({"employer_profile.broker_agency_accounts.is_active" => 1,
         "employer_profile.broker_agency_accounts.broker_agency_profile_id" => 1 },
         { name: "active_broker_accounts_broker_agency" })
  index({"employer_profile.broker_agency_accounts.is_active" => 1,
         "employer_profile.broker_agency_accounts.writing_agent_id" => 1 },
         { name: "active_broker_accounts_writing_agent" })

  # Strip non-numeric characters
  def fein=(new_fein)
    write_attribute(:fein, new_fein.to_s.gsub(/\D/, ''))
  end

  def primary_office_location
    office_locations.detect(&:is_primary?)
  end

  def self.default_search_order
    [[:legal_name, 1]]
  end

  def self.search_hash(s_rex)
    search_rex = Regexp.compile(Regexp.escape(s_rex), true)
    {
      "$or" => ([
        {"legal_name" => search_rex}
      ])
    }
  end

  def self.valid_carrier_names
    Rails.cache.fetch("carrier-names-at-#{TimeKeeper.date_of_record.year}", expires_in: 2.hour) do
      Organization.exists(carrier_profile: true).inject({}) do |carrier_names, org|
        carrier_names[org.carrier_profile.id.to_s] = org.carrier_profile.legal_name if Plan.valid_shop_health_plans("carrier", org.carrier_profile.id).present?
        carrier_names
      end
    end
  end

  def self.valid_carrier_names_for_options
    Organization.valid_carrier_names.invert.to_a
  end

  def office_location_kinds
    location_kinds = self.office_locations.select{|l| !l.persisted?}.flat_map(&:address).compact.flat_map(&:kind)
    # should validate only office location which are not persisted AND kinds ie. primary, mailing, branch 
    return if no_primary = location_kinds.detect{|kind| kind == 'work' || kind == 'home'}
    unless location_kinds.empty?
      if location_kinds.count('primary').zero?
        errors.add(:base, "must select one primary address")
      elsif location_kinds.count('primary') > 1
        errors.add(:base, "can't have multiple primary addresses")
      elsif location_kinds.count('mailing') > 1
        errors.add(:base, "can't have more than one mailing address")
      end
      if !errors.any?# this means that the validation succeeded and we can delete all the persisted ones
        self.office_locations.delete_if{|l| l.persisted?}
      end
    end
  end
end
