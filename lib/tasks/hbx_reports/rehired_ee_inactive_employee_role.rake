# Report: Rake task to Identify ReHired EE's with Inactive Employee_Role
# RAILS_ENV=production bundle exec rake reports:shop:rehired_ee_inactive_employee_role

require 'csv'
 
namespace :reports do
  namespace :shop do

    desc "Query To Identify ReHired EE's with Inactive Employee_Role"
    task :rehired_ee_inactive_employee_role, [:file] => :environment do

      field_names  = %w(hbx_id full_name employer fein)
      total_count = 0
      Dir.mkdir("hbx_report") unless File.exists?("hbx_report")
      file_path = "#{Rails.root}/hbx_report/rehired_ee_inactive_employee_role.csv"
      CSV.open(file_path, "w", force_quotes: true) do |csv|
        csv << field_names

        Person.all.each do |pr|
          begin
          if pr.employee_roles.all.count >= 2
            if (pr.employee_roles[-1].census_employee.employer_profile.id ==  pr.employee_roles[0].census_employee.employer_profile.id)
              legal_name = pr.employee_roles[-1].census_employee.employer_profile.organization.legal_name
              fein = pr.employee_roles[-1].census_employee.employer_profile.organization.fein
              if ((pr.employee_roles[-1].census_employee.aasm_state == 'eligible') && (pr.employee_roles[-1].census_employee.employee_role_id == nil) && (pr.employee_roles[0].census_employee.aasm_state == 'rehired'))
                csv << [pr.hbx_id, pr.full_name, legal_name, fein]
                total_count += 1
              end
            end
          end
          rescue
            puts "***bad record*** #{pr.hbx_id}, #{pr.full_name} #{legal_name} #{fein}" 
          end
        end
        puts "File path: %s. Total count of rehired EE's with inactive employee_roles: %d." %[file_path, total_count]
      end
    end
  end
end
