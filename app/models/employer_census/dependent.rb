class EmployerCensus::Dependent < EmployerCensus::Member

  EMPLOYEE_RELATIONSHIP_KINDS = %W[spouse domestic_partner child_under_26  child_26_and_over disabled_child_26_and_over]

  embedded_in :employee_family, class_name: "EmployerCensus::EmployeeFamily", inverse_of: :census_dependents

  validates :employee_relationship,
            presence: true,
            allow_blank: false,
            allow_nil:   false,
            inclusion: { 
              in: EMPLOYEE_RELATIONSHIP_KINDS, 
              message: "'%{value}' is not a valid employee relationship"
            }


end
