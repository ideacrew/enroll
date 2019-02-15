class EmployerProfile

  include Mongoid::Document
  include Mongoid::Timestamps

  field :entity_kind, type: String
  field :sic_code, type: String

  embeds_many :plan_years, cascade_callbacks: true, validate: true
  embedded_in :organization

  field :entity_kind, type: String
  field :sic_code, type: String

  field :no_ssn, type: Boolean, default: false
  field :enable_ssn_date, type: DateTime
  field :disable_ssn_date, type: DateTime

#  field :converted_from_carrier_at, type: DateTime, default: nil
#  field :conversion_carrier_id, type: BSON::ObjectId, default: nil

  # Workflow attributes
  field :aasm_state, type: String, default: "applicant"


  field :profile_source, type: String, default: "self_serve"
  field :contact_method, type: String, default: "Only Electronic communications"
  field :registered_on, type: Date, default: ->{ TimeKeeper.date_of_record }
  field :xml_transmitted_timestamp, type: DateTime

  def self.find(id)
  end

  def active_plan_year
  end

  def is_converting?

  end

  def census_employees
    []
  end
end
