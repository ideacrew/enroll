class CensusRoster

## NOTE: this model is deprecated!!

  include Mongoid::Document
  include Mongoid::Timestamps
  include Sortable

  field :employer_profile_id, type: BSON::ObjectId
  field :is_active, type: Boolean, default: true

  belongs_to :employer_profile
  # accepts_nested_attributes_for :employer_profile

  embeds_many :census_families,
    cascade_callbacks: true,
    validate: true
  accepts_nested_attributes_for :census_families, allow_destroy: true

  validates_presence_of :employer_profile_id

  index({"census_families._id" => 1}, { unique: true, sparse: true })
  index({"census_families.linked_at" => 1}, {sparse: true})
  index({"census_families.employee_role_id" => 1}, {sparse: true})
  index({"census_families.terminated" => 1})
  index({"census_families.benefit_group_assignments._id" => 1})
  index({"census_families.census_employee.last_name" => 1})
  index({"census_families.census_employee.dob" => 1})
  index({"census_families.census_employee.ssn" => 1})
  index({"census_families.census_employee.ssn" => 1,
         "census_families.census_employee.dob" => 1},
         {name: "ssn_dob_index"})


  def employer_profile=(new_employer_profile)
    raise ArgumentError.new("expected EmployerProfile") unless new_employer_profile.is_a? EmployerProfile
    self.employer_profile_id = new_employer_profile._id
    @employer_profile = new_employer_profile
  end

  def employer_profile
    return @employer_profile if defined? @employer_profile
    @employer_profile = EmployerProfile.find(:employer_profile_id)
  end

  def census_families_sorted
    return @census_families_sorted if defined? @census_families_sorted
    @census_families_sorted = census_families.unscoped.order_name_desc
  end

  def is_active?
    is_active
  end

  def eligible_to_enroll_count
  end

  def non_owner_enrollment_count
  end

  def total_enrolled_count
  end

  def enrollment_ratio
    (total_enrolled_count / eligible_to_enroll_count) unless eligible_to_enroll_count == 0
  end

  def is_enrollment_valid?
    enrollment_errors.blank? ? true : false
  end

  # Determine enrollment composition compliance with HBX-defined guards
  def enrollment_errors
    errors = {}
    # At least one employee who isn't an owner or family member of owner must enroll
    if non_owner_enrollment_count < HbxProfile::ShopEnrollmentNonOwnerParticipationMinimum
      errors.merge!(:non_owner_enrollment_count, "at least #{HbxProfile::ShopEnrollmentNonOwnerParticipationMinimum} non-owner employee must enroll")
    end

    # January 1 effective date exemption(s)
    unless effective_date.yday == 1
      # Verify ratio for minimum number of eligible employees that must enroll is met
      if enrollment_ratio < HbxProfile::ShopEnrollmentParticipationRatioMinimum
        errors.merge!(:enrollment_ratio, "number of eligible participants enrolling (#{employees_total_enrolled_count}) is less than minimum required #{employees_eligible_to_enroll_count * ShopEnrollmentParticipationMinimum}")
      end
    end

    errors
  end

  class << self 
    def find_census_families_by_person(person)
      self.all_of(
          "census_families.census_employee.ssn" => person.ssn,
          "census_families.census_employee.dob" => person.dob,
          "census_families.census_employee.linked_at" => nil
        ).only(:census_families).to_a
    end

    def find_families_by_person(person)
      organizations = match_census_employees(person)
      organizations.reduce([]) do |families, er|
        families << er.census_families.detect { |ef| ef.census_employee.ssn == person.ssn }
      end
    end

  end
end
