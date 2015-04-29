class Organization
  include Mongoid::Document
  include Mongoid::Timestamps
  include Mongoid::Versioning

  extend Mongorder

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


  index({ hbx_id: 1 }, { unique: true })
  index({ legal_name: 1 })
  index({ dba: 1 }, {sparse: true})
  index({ fein: 1 }, { unique: true })
  index({ is_active: 1 })

  # CarrierProfile child model indexes
  index({"carrier_profile._id" => 1}, { unique: true, sparse: true })

  # EmployerProfile child model indexes
  index({"employer_profile._id" => 1}, { unique: true, sparse: true })
  index({"employer_profile.broker_agency_profile_id" => 1}, {sparse: true})
  index({"employer_profile.writing_agent_id" => 1}, {sparse: true})
  index({"employer_profile.plan_years._id" => 1}, { unique: true, sparse: true })
  index({"employer_profile.plan_years.start_date" => 1})
  index({"employer_profile.plan_years.end_date" => 1})
  index({"employer_profile.plan_years.open_enrollment_start_on" => 1})
  index({"employer_profile.plan_years.open_enrollment_end_on" => 1})

  index({"employer_profile.employee_families._id" => 1}, { unique: true, sparse: true })
  index({"employer_profile.employee_families.linked_at" => 1}, {sparse: true})
  index({"employer_profile.employee_families.employee_role_id" => 1}, {sparse: true})
  index({"employer_profile.employee_families.terminated" => 1})
  index({"employer_profile.employee_families.census_employee.last_name" => 1})
  index({"employer_profile.employee_families.census_employee.dob" => 1})
  index({"employer_profile.employee_families.census_employee.ssn" => 1})
  index({"employer_profile.employee_families.census_employee.ssn" => 1,
         "employer_profile.employee_families.census_employee.dob" => 1},
         {name: "ssn_dob_index"})

  # BrokerAgencyProfile child model indexes
  index({"broker_agency_profile._id" => 1}, { unique: true, sparse: true })
  index({"broker_agency_profile.primary_broker_role_id" => 1}, { unique: true, sparse: true })
  index({"broker_agency_profile.market_kind" => 1})
  index({"broker_agency_profile.aasm_state" => 1})

  # def employee_family_details(person)
  #   return Organization.where(id: id).where(:"employer_profile.employee_families.census_employee.ssn" => person.ssn).last.employer_profile.employee_families.last
  # end

  # Strip non-numeric characters
  def fein=(new_fein)
    write_attribute(:fein, new_fein.to_s.gsub(/\D/, ''))
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
end
