class CensusMember
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

  embeds_one :address
  accepts_nested_attributes_for :address, reject_if: :all_blank, allow_destroy: true

  embeds_one :email
  accepts_nested_attributes_for :email, reject_if: :all_blank, allow_destroy: true

  validates_presence_of :first_name, :last_name, :dob, :employee_relationship

  validates :gender,
    allow_blank: true,
    inclusion: { in: GENDER_KINDS, message: "%{value} is not a valid gender" }

  validates :ssn,
    length: { minimum: 9, maximum: 9, message: "SSN must be 9 digits" },
    allow_blank: true,
    numericality: true

  validate :date_of_birth_is_past

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

  def date_of_birth
    self.dob.blank? ? nil : self.dob.strftime("%m/%d/%Y")
  end

  def date_of_birth=(val)
    self.dob = Date.strptime(val, "%Y-%m-%d").to_date rescue nil
  end

  def full_name
   [first_name, middle_name, last_name, name_sfx].compact.join(" ")
  end

  def date_of_birth_is_past
    return unless self.dob.present?
    errors.add(:dob, "future date: %{self.dob} is invalid date of birth") if TimeKeeper.date_of_record < self.dob
  end
end
