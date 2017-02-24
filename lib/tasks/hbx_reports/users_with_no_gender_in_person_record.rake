# Report: Rake task to generate two reports to find users without gender assigned to person_record


require 'csv'

namespace :report do
  namespace :user_account do

    desc "List of users with no gender assignment to person account"
    task :with_no_gender_in_person_account => :environment do


      users = User.all

      #first name, last name, hbx id, email, ER role (y/n), consumer role (y/n), employer
      field_names  = %w(
               username
               user_first_name
               user_last_name
               person_hbx_id
               has_employer_role(Y/N)
               has_consumer_role(Y/N)
               employer_legal_name
             )
      processed_count = 0
      Dir.mkdir("hbx_report") unless File.exists?("hbx_report")
      file_name = "#{Rails.root}/hbx_report/users_account_with_no_gender_in_person_account.csv"

      CSV.open(file_name, "w", force_quotes: true) do |csv|
        csv << field_names

        users.each do |user|
          if user.person.present?
            if user.person.gender.nil?
                csv << [
                    user.person.first_name,
                    user.person.last_name,
                    user.person.hbx_id,
                    user.roles.include?("employer_staff") ? "Y" : "N",
                    user.roles.include?("consumer") ? "Y" : "N",
                    user.roles.include?("employer_staff") ? EmployerProfile.find(user.person.all_employer_staff_roles.first.employer_staff_roles.first._id) : "Not available"
                ]
                processed_count += 1
            end
          end
        end
        puts "Total users with no gender in person account count #{processed_count} and users account output file: #{file_name}" unless Rails.env == 'test'
      end
    end
  end
end
