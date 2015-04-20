module Forms
  class EmployeeRole < SimpleDelegator
    attr_accessor :employee_role_id
    attr_accessor :census_employee_id
    attr_accessor :census_family_id
    attr_accessor :employer_profile_id
    attr_accessor :organization_id

    WRAPPED_ATTRIBUTES = [
      "employee_role_id",
      "census_employee_id",
      "census_family_id",
      "employer_profile_id",
      "organization_id"
    ]

    attr_accessor(*WRAPPED_ATTRIBUTES)

    def initialize(person)
      super(person)
    end

    def self.model_name
      Person.model_name
    end

    def self.find(id)
      self.new(Person.find(id))
    end

    def self.from_parameters(opts = {})
      for_wrapper, for_person = clean_attributes(opts)
      p = Person.new(for_person)
      wrapper = self.new(p)
      wrapper.assign_attributes(for_wrapper)
      wrapper
    end

    def self.clean_attributes(hsh)
      atts = hsh.dup.stringify_keys
      for_wrapper, for_person = atts.partition { |k, v| WRAPPED_ATTRIBUTES.include?(k) }
      [Hash[for_wrapper], Hash[for_person]]
    end

    def assign_attributes(options = {})
      options.each_pair do |k, v|
        self.send("#{k}=", v)
      end
    end

    def organization
      @organization ||= Organization.find(organization_id)
    end

    def employer_profile
      @employer_profile ||= organization.employer_profile
    end

    def benefit_group
      @benefit_group ||= census_family.benefit_group
    end

    def census_family
      @census_family ||= @employer_profile.employer_families.detect { |cf| cf.id == census_family_id}
    end

    def census_employee
      @census_employee ||= census_family.census_employee
    end
  end
end
