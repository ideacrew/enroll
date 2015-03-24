class EmployerCensus::Member
  include Mongoid::Document
  include Mongoid::Timestamps

  GENDER_KINDS = %W(male female)

  field :first_name, type: String
  field :middle_name, type: String
  field :last_name, type: String
  field :name_sfx, type: String

  field :ssn, type: String
  field :dob, type: Date
  field :gender, type: String

  field :employee_relationship, type: String

  embedded_in :family, class_name: "EmployerCensus::Family"

  embeds_one :address
  embeds_one :email

  validates_presence_of :first_name, :last_name, :dob, :employee_relationship

  validates :gender,
    allow_blank: true,
    inclusion: { in: GENDER_KINDS, message: "%{value} is not a valid gender" }

  validates :ssn,
    length: { minimum: 9, maximum: 9, message: "SSN must be 9 digits" },
    allow_blank: true,
    numericality: true


  # Strip non-numeric chars from ssn
  # SSN validation rules, see: http://www.ssa.gov/employer/randomizationfaqs.html#a0=12
  def ssn=(val)
    return if val.blank?
    write_attribute(:ssn, val.to_s.gsub(/[^0-9]/i, ''))
  end

  def gender=(val)
    return if val.blank?
    write_attribute(:gender, val.downcase)
  end

  def dob_string
    self.dob.blank? ? "" : self.dob.strftime("%Y%m%d")
  end


end
