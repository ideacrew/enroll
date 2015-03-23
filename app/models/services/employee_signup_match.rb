module Services
  class EmployeeSignupMatch
    def call(consumer_identity)
      consumer_identity.match_census_employee      
    end 
  end
end
