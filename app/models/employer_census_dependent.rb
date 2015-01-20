class EmployerCensusDependent < EmployerCensusMember

  EMPLOYEE_RELATIONSHIP_KINDS = %W[spouse dependent]

  embedded_in :employer_census_family

  validates :employee_relationship,
            presence: true,
            allow_blank: false,
            allow_nil:   false,
            inclusion: { 
              in: EMPLOYEE_RELATIONSHIP_KINDS, 
              message: "'%{value}' is not a valid employee relationship"
            }
end
