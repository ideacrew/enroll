#This rake task will generate the report with all the enrollments for an year having aasm_state coverage selected and for all the family members having verification outstanding.

require 'csv'

namespace :report do

  desc "List of all people in the enroll database"
  task :member_enrollments_having_verification_pending => :environment do
    year = ENV['year'].to_i

    Dir.mkdir("hbx_report") unless File.exists?("hbx_report")
    file_name = "#{Rails.root}/hbx_report/verification_pending_and_enrollments_report_#{TimeKeeper.date_of_record.strftime("%m_%d_%Y")}.csv"

    outstanding_people = Person.where({:"consumer_role" => {"$exists" => true},:"consumer_role.aasm_state" => "verification_outstanding"})

    field_names = %w(
                  Subscriber_ID
                  Member_ID
                  First_Name
                  Last_Name
                  Consumer_Role_State
                  Enrollment_ID
                  Enrollment_Market_Kind
                  Enrollment_Effective_on
                  Enrollment_State
                        )
    if outstanding_people.present?
      CSV.open(file_name, "w") do |csv|
        csv << field_names

        outstanding_people.each do |person|
          person.families.each do |family|
            all_active_enrollments = family.active_household.hbx_enrollments.individual_market.enrolled
            active_enrollments = all_active_enrollments.where(:"hbx_enrollment_members.applicant_id" => family.family_members.where(person_id: person.id).first.id).and(:"effective_on" => Date.new(year, 1, 1)..Date.new(year, 12, 31))
            if active_enrollments.present?
              active_enrollments.each do |enrollment|
                if enrollment.aasm_state == "coverage_selected"
                  csv << [enrollment.subscriber.person.hbx_id,
                          person.hbx_id,
                          person.first_name,
                          person.last_name,
                          person.consumer_role.aasm_state,
                          enrollment.hbx_id,
                          enrollment.kind,
                          enrollment.effective_on,
                          enrollment.aasm_state
                  ]
                end
              end
            end
          end
        end
        puts "Report Generated" unless Rails.env.test?
      end
    end
  end
end