require 'csv'

namespace :reports do
  namespace :shop do

    desc "Employee with no address account information"
    task :employee_with_no_address_list => :environment do
      # collecting all the employee list that have no address

      census_employees=CensusEmployee.linked.all

      #In formation need to provide Primary Subscriber HBX ID, First Name, Last Name, ER Legal Name, FEIN.


          field_names  = %w(
          primary_subscriber_hbx_id
          first_name
          last_name
          er_legal_name
          fein
        )
      processed_count = 0

      Dir.mkdir("hbx_report") unless File.exists?("hbx_report")
      file_name = "#{Rails.root}/hbx_report/employee_with_no_address_list.csv"

      CSV.open(file_name, "w", force_quotes: true) do |csv|
        csv << field_names
        census_employees.each do |census_employee|

         unless census_employee.employee_role.person.addresses.exists?
          csv << [
              census_employee.employee_role.person.hbx_id,
              census_employee.first_name,
              census_employee.last_name,
              census_employee.employer_profile.organization.legal_name,
              census_employee.employer_profile.organization.fein
        ]
        end
        end
        processed_count += 1
      end
      puts "List of all the employees with no address #{file_name}"
    end
  end
end