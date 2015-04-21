module Services
  class EmployeeSignupMatch
    def initialize(form_factory = Factories::MatchedEmployee, census_family_finder = EmployerProfile)
      @form_factory = form_factory.new
      @census_family_finder = census_family_finder
    end

    def call(consumer_identity)
      census_families = @census_family_finder.find_census_families_by_person(consumer_identity)
      return nil if census_families.empty?
      census_employee = census_families.first.census_employee
      [census_employee, @form_factory.build(consumer_identity, census_employee, consumer_identity.match_person)]
    end
  end
end
