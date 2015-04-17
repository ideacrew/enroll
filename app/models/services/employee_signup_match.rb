module Services
  class EmployeeSignupMatch
    def initialize(form_factory = Factories::MatchedEmployee)
      @form_factory = form_factory.new
    end

    def call(consumer_identity)
      found_employees = consumer_identity.match_census_employees
      return nil if found_employees.empty?
      linkable_employees = found_employees.select { |fe| fe.is_linkable? }
      return nil if linkable_employees.empty?
      @form_factory.build(consumer_identity, linkable_employees.first, consumer_identity.match_person)
    end
  end
end
