require 'csv'

namespace :reports do
  namespace :shop do

    desc "Employee with no address account information"
    task :employee_with_no_address_list => :environment do

      census_employees=CensusEmployee.linked.all
      field_names= %w(
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
        total_records = census_employees.count()
        offset =0
        step=100
        while offset <= total_records do
          if offset+step<=total_records
              ces= census_employees.limit(step).offset(offset)
          else
              ces= census_employees.limit(step).offset(total_records)
          end
          ces.each do |ce|
            unless ce.employee_role.person.addresses.exists?
              csv << [
                  ce.employee_role.person.hbx_id,
                  ce.first_name,
                  ce.last_name,
                  ce.employer_profile.organization.legal_name,
                  ce.employer_profile.organization.fein
              ]
              processed_count += 1
            end
          end
          offset=offset+step
        end
      end
      puts "The report has been generated as #{file_name}"
      end
    end
end