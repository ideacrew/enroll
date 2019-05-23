class BenefitGroupAssignment
  include Mongoid::Document
  include Mongoid::Timestamps
  include AASM

  embedded_in :census_employee

  field :benefit_group_id, type: BSON::ObjectId
  field :benefit_package_id, type: BSON::ObjectId # Engine Benefit Package

  # Represents the most recent completed enrollment
  field :hbx_enrollment_id, type: BSON::ObjectId

  field :start_on, type: Date
  field :end_on, type: Date
  field :coverage_end_on, type: Date
  field :aasm_state, type: String, default: "initialized"
  field :is_active, type: Boolean, default: true
  field :activated_at, type: DateTime

  scope :active,         -> { where(:is_active => true) }
  scope :effective_on,   ->(effective_date) { where(:start_on => effective_date) }


  def benefit_group=(new_benefit_group)
    warn "[Deprecated] Instead use benefit_package=" unless Rails.env.test?
    if new_benefit_group.is_a?(BenefitGroup)
      self.benefit_group_id = new_benefit_group._id
      return @benefit_group = new_benefit_group
    end
    self.benefit_package=(new_benefit_group)
  end

  def benefit_group
    return @benefit_group if defined? @benefit_group
    warn "[Deprecated] Instead use benefit_package" unless Rails.env.test?
    if is_case_old?
      return @benefit_group = BenefitGroup.find(self.benefit_group_id)
    end
    benefit_package
  end

  def benefit_package=(new_benefit_package)
    raise ArgumentError.new("expected BenefitPackage") unless new_benefit_package.is_a? BenefitSponsors::BenefitPackages::BenefitPackage
    self.benefit_package_id = new_benefit_package._id
    @benefit_package = new_benefit_package
  end

  def benefit_package
    return if benefit_package_id.nil?
    return @benefit_package if defined? @benefit_package
    @benefit_package = BenefitSponsors::BenefitPackages::BenefitPackage.find(benefit_package_id)
  end

  def is_case_old?
    self.benefit_package_id.blank?
  end

  def plan_year
    return benefit_group.plan_year if is_case_old?
    benefit_application
  end

  def benefit_application
    benefit_package.benefit_application if benefit_package.present?
  end

  def hbx_enrollment
    return @hbx_enrollment if defined? @hbx_enrollment
    @hbx_enrollment = HbxEnrollment.find(self.hbx_enrollment_id) if hbx_enrollment_id.present?
  end

  def hbx_enrollment=(new_hbx_enrollment)
    raise ArgumentError.new("expected HbxEnrollment") unless new_hbx_enrollment.is_a? HbxEnrollment
    self.hbx_enrollment_id = new_hbx_enrollment._id
    @hbx_enrollment = new_hbx_enrollment
  end

  def benefit_package=(new_benefit_package)
    raise ArgumentError.new("expected BenefitPackage") unless new_benefit_package.is_a? BenefitSponsors::BenefitPackages::BenefitPackage
    self.benefit_package_id = new_benefit_package._id
    @benefit_package = new_benefit_package
  end

  def benefit_package
    return if benefit_package_id.nil?
    return @benefit_package if defined? @benefit_package
    @benefit_package = BenefitSponsors::BenefitPackages::BenefitPackage.find(benefit_package_id)
  end

  def benefit_application
    benefit_package.benefit_application if benefit_package.present?
  end

  def make_active
    census_employee.benefit_group_assignments.each do |bg_assignment|
      if bg_assignment.is_active? && bg_assignment.id != self.id
        bg_assignment.update_attributes(is_active: false, end_on: [start_on - 1.day, bg_assignment.start_on].max)
      end
    end

    update_attributes(is_active: true, activated_at: TimeKeeper.datetime_of_record) unless is_active?
  end

  def covered_families
    Family.where({
      "households.hbx_enrollments.benefit_group_assignment_id" => BSON::ObjectId.from_string(self.id)
    })
  end

  def hbx_enrollments
    covered_families.inject([]) do |enrollments, family|
      family.households.each do |household|
        enrollments += household.hbx_enrollments.show_enrollments_sans_canceled.select do |enrollment|
          enrollment.benefit_group_assignment_id == self.id
        end.to_a
      end
      enrollments
    end
  end

  aasm do
    state :initialized, initial: true
    state :coverage_selected
    state :coverage_waived
    state :coverage_terminated
    state :coverage_void
    state :coverage_renewing
    state :coverage_expired

  end
end
