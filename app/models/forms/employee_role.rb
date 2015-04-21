require 'factories/enrollment_factory'

module Forms
  class EmployeeRole < SimpleDelegator
    WRAPPED_ATTRIBUTES = [
      "census_employee_id",
      "census_family_id",
      "employer_profile_id",
      "organization_id",
      "hired_on",
      "terminated_on",
      "benefit_group_id"
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

    def save
     super.tap do |val|
       if val
         add_employee_role(__getobj__, for_wrapper)
       end
     end
    end

    def add_employee_role(person_record, attrs)
      emp_attrs = attrs.dup.reject { |k,v| ["organization_id","census_employee_id"].include?(k.to_s) }
      emp_role = ::EmployeeRole.new(emp_attrs)
      person_record.employee_roles << emp_role
      census_family.link_employee_role(emp_role)
      Family.find_or_initialize_by_employee_role(emp_role)
    end

    def update_attributes(opts = {})
      for_wrapper, for_person = self.class.clean_attributes(opts)
      assign_attributes(for_wrapper)
      for_person.each_pair do |k,v|
        __getobj__.write_attribute(k, v)
      end
      __getobj__.save.tap do |val|
        if val
          add_employee_role(__getobj__, for_wrapper)
        end
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
      @census_family ||= employer_profile.employee_families.detect { |cf| cf.id.to_s == census_family_id.to_s}
    end

    def census_employee
      @census_employee ||= census_family.census_employee
    end
  end
end
