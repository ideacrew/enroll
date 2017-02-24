# Report: Rake task to generate report to find users without gender assigned to census employee record


require 'csv'
namespace :report do
  namespace :user_account do
    desc "List of users with no gender assignment to person account"
    task :with_no_gender_in_census_ee_account => :environment do
      users = User.all
      field_names  = %w(
               user_first_name
               user_last_name
               person_hbx_id
               has_employer_role(Y/N)
               has_consumer_role(Y/N)
               employer_legal_name
             )
      processed_count = 0
      Dir.mkdir("hbx_report") unless File.exists?("hbx_report")
      file_name = "#{Rails.root}/hbx_report/users_account_with_no_gender_in_census_ee_account.csv"
      CSV.open(file_name, "w", force_quotes: true) do |csv|
        csv << field_names
        users.each do |user|
          if (user.person.present?)&&(user.try(:person).has_active_employee_role?)
            census_employees=user.person.active_census_employees
            census_employees.each do |ce|
              if ce.gender.nil?
                  csv << [
                      user.person.first_name,
                      user.person.last_name,
                      user.person.hbx_id,
                      user.has_employer_staff_role? ? "Y" : "N",
                      user.has_consumer_role? ? "Y" : "N",
                      if user.has_employer_staff_role?
                        staff_id=user.person.employer_staff_roles.first._id
                        EmployerProfile.find(staff_id).nil? ? "Not available" : EmployerProfile.find(staff_id).first.legal_name
                      else
                        "Not available"
                      end
                  ]
                  processed_count += 1
                  break
                end
            end
          end
        end
        puts "Total users with no gender in person account count #{processed_count} and users account output file: #{file_name}" unless Rails.env == 'test'
      end
    end
  end
end
