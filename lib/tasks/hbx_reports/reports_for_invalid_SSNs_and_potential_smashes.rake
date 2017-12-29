# Run the following rake task: RAILS_ENV=production bundle exec rake reports:people_with_invalid_SSN_and_multiple_families
require 'csv'
require File.join(Rails.root, "spec/factories/helpers/factory_helper.rb")
namespace :reports do
  desc "Users with Invalid SSN's & people having more than 1 family"
  task :people_with_invalid_SSN_and_multiple_families => :environment do
    person_count = 0
    families_size = 0
    census_employee_count = 0

    field_names  = %w(
      HBX_ID
      FirstName
      LastName
      DOB
      SSN
      Is_Primary
      Has_Employee_Role
      Has_IVL_Role
      Has_Employer_Role
    )

    census_fields = %w(
      FirstName
      LastName
      DOB
      SSN
      Aasm_State
      Employer_Name
      Is_Employee_Role_Present
    )

    file_name = "#{Rails.root}/public/people_with_invalid_SSNs.csv"
    file_name2 = "#{Rails.root}/public/people_having_multiple_families.csv"
    file_name3 = "#{Rails.root}/public/census_records_with_invalid_SSNs.csv"

    def is_primary?(person)
      person.primary_family.present?
    end

    def has_employee_role?(person)
      person.employee_roles?
    end

    def has_ivl_role?(person)
      person.consumer_role?
    end

    def has_employer_staff_role?(person)
      person.employer_staff_roles?
    end

    def employer_name(census_employee)
      census_employee.employer_profile.legal_name if census_employee.employer_profile.present?
    end

    persons = Person.where(:"encrypted_ssn".ne => nil)
    census_employees = CensusEmployee.all

    CSV.open(file_name, "w", force_quotes: true) do |row|
      row << field_names
      persons.each do |person|
        begin
          if ssn_validator(person)
            person_count = person_count + 1
            row << [
              person.hbx_id,
              person.first_name,
              person.last_name,
              person.dob,
              person.ssn,
              is_primary?(person),
              has_employee_role?(person),
              has_ivl_role?(person),
              has_employer_staff_role?(person)
            ]
          end
        rescue => e
          puts "Bad record: Exception: #{e}"
        end
      end
      puts "People with invalid SSN size: #{person_count}"
    end

    CSV.open(file_name2, "w", force_quotes: true) do |row|
      row << field_names
      Person.all.each do |person|
        begin
          if person.families.size > 1
            families_size = families_size + 1
            row << [
              person.hbx_id,
              person.first_name,
              person.last_name,
              person.dob,
              person.ssn,
              is_primary?(person),
              has_employee_role?(person),
              has_ivl_role?(person),
              has_employer_staff_role?(person)
            ]
          end
        rescue => e
          puts "Bad record: Exception: #{e}"
        end
      end
      puts "People with multiple families: #{families_size}"
    end

    CSV.open(file_name3, "w", force_quotes: true) do |row|
      row << census_fields
      census_employees.each do |census_employee|
        begin
          if ssn_validator(census_employee)
            census_employee_count = census_employee_count + 1
            row << [
              census_employee.first_name,
              census_employee.last_name,
              census_employee.dob,
              census_employee.ssn,
              census_employee.aasm_state,
              employer_name(census_employee),
              census_employee.employee_role.present?
            ]
          end
        rescue => e
          puts "Bad record: Exception: #{e}"
        end
      end
      puts "Census Records with invalid SSN count: #{census_employee_count}"
    end
  end
end