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


  def benefit_group=(benefit_package)
    self.benefit_group_id = benefit_package.id
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
