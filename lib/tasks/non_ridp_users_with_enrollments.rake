# Run the following rake task: RAILS_ENV=production bundle exec rake reports:non_ridp_users_with_enrollments

require 'csv'
namespace :reports do
  desc 'Non-curam Users in a time frame where users can bypass RIDP by changing URL issue present'
  task :non_ridp_users_with_enrollments => :environment do
    start_date = Date.new(2016,1,7)
    end_date = Date.new(2017,2,7)
    count = 0

    field_names  = %w(
      HBX_ID
      FULL_NAME
      SSN
      DOB
    )

    file_name = "#{Rails.root}/public/non_ridp_users_with_enrollments.csv"
    
    CSV.open(file_name, "w", force_quotes: true) do |row|
      row << field_names
      Person.all_consumer_roles.where(:"created_at" => { "$gte" => start_date, "$lte" => end_date}).each do |person|
        if person.user.present? && !person.user.identity_verified? && person.primary_family.present? && person.primary_family.e_case_id.blank?
          if person.primary_family.active_household.present? && person.primary_family.active_household.hbx_enrollments.present?
            count = count + 1
            row << [
              person.hbx_id,
              person.full_name,
              person.ssn,
              person.dob
            ]
          end
        end
      end
      puts "persons count: #{count}"
    end
  end
end
