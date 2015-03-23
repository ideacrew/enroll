module Services
  class EmployeeSignupMatch
    def call(consumer_identity)
      found_employees = consumer_identity.match_census_employees
      return nil if found_employees.empty?
    end 
  end
end
