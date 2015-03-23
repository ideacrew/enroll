module Services
  class EmployeeSignupMatch
    def call(consumer_identity)
      found_employee = consumer_identity.match_census_employee
      return nil if found_employee.blank?
    end 
  end
end
