class CensusDependent < CensusMember

  EMPLOYEE_RELATIONSHIP_KINDS = %W[spouse domestic_partner child_under_26  child_26_and_over disabled_child_26_and_over]

  validates :dob, :uniqueness => {:scope => [:first_name, :last_name], message: "dependent for this census employee with same DOB and first and last name already exists."}


  embedded_in :census_employee

  validates :employee_relationship,
            presence: true,
            allow_blank: false,
            allow_nil:   false,
            inclusion: {
              in: EMPLOYEE_RELATIONSHIP_KINDS,
              message: "'%{value}' is not a valid employee relationship"
            }

  def self.find(census_dependent_id)
    return [] if census_dependent_id.nil?
    census_employee = CensusEmployee.where("census_dependents._id" => BSON::ObjectId.from_string(census_dependent_id)).first
    census_employee.census_dependents.detect { |member| member._id.to_s == census_dependent_id.to_s } unless census_employee.blank?
  end
end
