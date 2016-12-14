require 'csv'

namespace :reports do
  namespace :shop do

    desc "Employee with no address account information"
    task :employee_with_no_address_list => :environment do
      people= Person.all_employee_roles.where(:'addresses'.exists=>false)
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
        total_records = people.count()
        offset =0
        step=100
        while offset <= total_records do
          if offset+step<=total_records
              ppl= people.limit(step).offset(offset)
          else
              ppl= people.limit(step).offset(total_records)
          end
          ppl.each do |person|
            person.employee_roles.each do |employee_role|
                csv << [
                    person.hbx_id,
                    person.first_name,
                    person.last_name,
                    employee_role.try(census_employee).try(employer_profile).try(organization).try(legal_name),
                    employee_role.census_employee.try(employer_profile).try(organization).try(fein)
                ]
                processed_count += 1
            end
          end
          offset=offset+step
        end
      end
      puts "The report has been generated as #{file_name}" unless Rails.env.test?
      end
    end
end