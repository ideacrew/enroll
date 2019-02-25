# RAILS_ENV=production bundle exec rake recurring:ivl_reminder_notices
namespace :recurring do
  desc "an automation task that sends out verification reminder notifications to IVL individuals"
  task ivl_reminder_notices: :environment do
    families = Family.where(:"households.hbx_enrollments"=>{"$elemMatch"=>{:is_any_enrollment_member_outstanding => true, 
      :"kind".in => ["individual", "unassisted_qhp", "insurance_assisted_qhp", "streamlined_medicaid", "emergency_medicaid", "hcr_chip"], 
      :"aasm_state".in => HbxEnrollment::ENROLLED_AND_RENEWAL_STATUSES}})
    puts "families #{families.count}" unless Rails.env.test?
    date = TimeKeeper.date_of_record
    families.each do |family|
      begin
        next if family.has_valid_e_case_id? #skip assisted families
        consumer_role = family.primary_applicant.person.consumer_role
        person = family.primary_applicant.person
        if consumer_role.present? && (family.best_verification_due_date > date)
          case (family.best_verification_due_date.to_date.mjd - date.mjd)
          when 85
            IvlNoticesNotifierJob.perform_later(person.id.to_s, "first_verifications_reminder")
            puts "Sent first_verifications_reminder to #{person.hbx_id}" unless Rails.env.test?
          when 70
            IvlNoticesNotifierJob.perform_later(person.id.to_s, "second_verifications_reminder")
            puts "Sent second_verifications_reminder to #{person.hbx_id}" unless Rails.env.test?
          when 45
            IvlNoticesNotifierJob.perform_later(person.id.to_s, "third_verifications_reminder")
            puts "Sent third_verifications_reminder to #{person.hbx_id}" unless Rails.env.test?
          when 30
            IvlNoticesNotifierJob.perform_later(person.id.to_s, "fourth_verifications_reminder")
            puts "Sent fourth_verifications_reminder to #{person.hbx_id}" unless Rails.env.test?
          end
        end
      rescue Exception => e
        Rails.logger.error {"Unable to send verification reminder notices to #{person.hbx_id} due to #{e}"}
      end
    end
  end
end