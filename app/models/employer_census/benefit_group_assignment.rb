class EmployerCensus::BenefitGroupAssignment
  include Mongoid::Document
  include Mongoid::Timestamps

  embedded_in :employee_family, class_name: "EmployerCensus::EmployeeFamily", inverse_of: :benefit_group_assignments

  field :benefit_group_id, type: BSON::ObjectId
  field :start_on, type: Date
  field :end_on, type: Date
  field :is_active, type: Boolean, default: true

  validates_presence_of :benefit_group_id, :start_on
  # validate :model_integrity

  def self.new_from_group_and_roster_family(ben_group, family)
    family.benefit_group_assignments.new(
      benefit_group_id: ben_group.id,
      start_on: [ben_group.start_on, family.hired_on].compact.max,
      end_on: [ben_group.end_on, family.terminated_on].compact.min
    )
  end

  def overlaps?(other_assignment)
    (start_on..end_on).overlaps?((other_assignment.start_on..other_assignment.end_on))
  end

  def benefit_group=(new_benefit_group)
    raise ArgumentError("expected BenefitGroup") unless new_benefit_group.is_a? BenefitGroup
    self.benefit_group_id = new_benefit_group._id
    @benefit_group = new_benefit_group
  end

  def benefit_group
    return @benefit_group if defined? @benefit_group
    @benefit_group = BenefitGroup.find(self.benefit_group_id) unless benefit_group_id.blank?
  end

  def is_active?
    self.is_active
  end

  def self.find(id)
    id = BSON::ObjectId.from_string(id) if id.is_a? String
    orgs = Organization.where(:"employer_profile.employee_families.benefit_group_assignments._id" => id).entries
    found_value = catch(:found_benefit_group_assignment) do
      orgs.each do |org|
        org.employer_profile.employee_families.each do |family|
          family.benefit_group_assignments.each do |bga|
            if bga.id == id
              throw :found_benefit_group_assignment, bga
            end
          end
        end
      end
      raise Mongoid::Errors::DocumentNotFound, "BenefitGroupAssignment #{bga}"
    end
    return found_value
  end

private
  def model_integrity
    self.errors.add(:benefit_group, "benefit_group required") unless benefit_group.present?
  end
end
