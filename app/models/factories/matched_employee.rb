module Factories
  class MatchedEmployee
    def build(consumer_identity, roster_employee, person)
      person_form = person
      if !person_form
        person_form = Person.new({ 
          :date_of_birth => consumer_identity.date_of_birth,
          :ssn => consumer_identity.ssn
        })
        build_address_from_employee(person_form, roster_employee)
      end
      person_form.user_id = consumer_identity.user_id
      populate_identity_properties(person_form, consumer_identity)
      build_nested_models(person_form)
      build_employee_role(person_form, roster_employee)
      person_form
    end

    def populate_identity_properties(person, ci)
      copy_properties(
        ci,
        person,
        [:first_name, :last_name, :middle_name, :name_pfx, :name_sfx, :gender]
      )
    end

    def copy_properties(from, to, props)
      props.each do |prop|
        copy_property(from, to, prop)
      end
    end

    def copy_property(from, to, prop)
      to.send("#{prop}=", from.send(prop))
    end

    def build_nested_models(person)

      ["home","mobile","work","fax"].each do |kind|
        person.phones.build(kind: kind) if person.phones.select{|phone| phone.kind == kind}.blank?
      end

      Address::KINDS.each do |kind|
        person.addresses.build(kind: kind) if person.addresses.select{|address| address.kind == kind}.blank?
      end

      ["home","work"].each do |kind|
        person.emails.build(kind: kind) if person.emails.select{|email| email.kind == kind}.blank?
      end
    end

    def build_employee_role(person, census_employee)
      emp_family = census_employee.employee_family
      emp_role = EmployeeRole.new
      copy_properties(
        census_employee,
        emp_role,
        [:hired_on, :terminated_on]
      )
      copy_properties(
        emp_family, 
        emp_role,
        [:benefit_group_id]
      )
      emp_role.employer_profile_id = emp_family.employer_profile.id
      emp_role.census_family_id = emp_family.id
      person.employee_roles.new(emp_role.attributes)
    end

    def build_address_from_employee(person_form, census_employee)
      if census_employee.address.present?
        person_form.addresses.new(census_employee.address.attributes)
      end
    end
  end
end
