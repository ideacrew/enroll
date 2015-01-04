class Consumer
  include Mongoid::Document
  include Mongoid::Timestamps

  embedded_in :person

  CITIZEN_STATUS_KINDS = %W[
      us_citizen
      naturalized_citizen
      alien_lawfully_present
      lawful_permanent_resident
      indian_tribe_member
      undocumented_immigrant
      not_lawfully_present_in_us
  ]

  field :ethnicity, type: String, default: ""
  field :race, type: String, default: ""
  field :birth_location, type: String, default: ""
  field :marital_status, type: String, default: ""

  field :citizen_status, type: String
  field :is_state_resident, type: Boolean, default: true
  field :is_incarcerated, type: Boolean, default: false
  field :is_applicant, type: Boolean, default: true
  field :is_disabled, type: Boolean, default: false

  field :is_tobacco_user, type: String, default: "unknown"
  field :language_code, type: String
  field :is_active, type: Boolean, default: true


  delegate :hbx_assigned_id, to: :person, allow_nil: true
  delegate :ssn, :ssn=, to: :person, allow_nil: true
  delegate :dob, :dob=, to: :person, allow_nil: true
  delegate :gender, :gender=, to: :person, allow_nil: true

  # belongs_to :family

  validates_presence_of :person, :ssn, :dob, :gender, :is_incarcerated, :is_applicant, 
    :is_state_resident, :citizen_status, :is_applicant

  validates :citizen_status,
    inclusion: { in: CITIZEN_STATUS_KINDS, message: "%{value} is not a valid citizen status" },
    allow_blank: false

  scope :all_under_age_twenty_six, ->{ gt(:'dob' => (Date.today - 26.years))}
  scope :all_over_age_twenty_six,  ->{lte(:'dob' => (Date.today - 26.years))}

  # TODO: Add scope that accepts age range
  # scope :all_between_age_range, ->(range) {}

  scope :all_over_or_equal_age, ->(age) {lte(:'dob' => (Date.today - age.years))}
  scope :all_under_or_equal_age, ->(age) {gte(:'dob' => (Date.today - age.years))}

  def is_active?
    self.is_active
  end

  def parent
    raise "undefined parent: Person" unless person? 
    self.person
  end

end
