require 'csv'
# The task to run is RAILS_ENV=production bundle exec rake reports:consumer_role_with_no_identity_veridication_report

namespace :reports do
  desc 'List of people with consumer role and not verified user'
  task consumer_role_with_no_identity_veridication_report: :environment do
    file_name = "#{Rails.root}/consumer_role_with_no_identity_verification_report.csv"
    field_names  = %w(
                      Hbx_id
                      Ivl_role
                      EE_role
                      Current_plan_name
                     )
    CSV.open(file_name, "w", force_quotes: true) do |csv|
      csv << field_names
      people = Person.all_consumer_roles.active
      people.each do |person|
        begin
          if person.has_active_consumer_role? && !person.user.nil?
            unless person.completed_identity_verification?
              hbx_id = person.hbx_id
              ivl_role = person.consumer_role.present? ? 'Y' : 'N'
              ee_role = person.active_employee_roles.present? ? 'Y' : 'N'
              active_enrollments = person.primary_family.active_household.active_hbx_enrollments

              plan_names = active_enrollments.collect() do |list, enrollment|
                if enrollment.kind=="individual" 
                  list << enrollment.plan.name 
                end
                list
              end
              unless plan_names.uniq.empty?
                csv <<  [ hbx_id,
                          ivl_role,
                          ee_role,
                          plan_names.uniq
                        ]
              end
            end
          end
        rescue => e
          puts "Bad person record, error: #{e}" unless Rails.env.test?
        end
      end
    end
  end
end  


