
namespace :recurring do
  desc "an automation task that sends out verification reminder notifications to IVL individuals"
  task ivl_reminder_notices: :environment do
    families = Family.where({
      "households.hbx_enrollments" => {
        "$elemMatch" => {
        "aasm_state" => { "$in" => ["enrolled_contingent"] },
        } }
        })
    puts "families #{families.count}" unless Rails.env.test?
    date = TimeKeeper.date_of_record
    families.each do |family|
      health_enrollment = family.enrollments.detect{ |e| e.enrolled_contingent? && e.effective_on.year == date.year && e.coverage_kind == "health"} #skipping assisted individuals
      next if family.e_case_id.present? || (health_enrollment.present? && (health_enrollment.applied_aptc_amount > 0) || health_enrollment.plan.is_csr?)
      consumer_role = family.primary_applicant.person.consumer_role
      person = family.primary_applicant.person
      if consumer_role.present? && (family.best_verification_due_date > date)
        begin
          case (family.best_verification_due_date.to_date.mjd - date.mjd)
            when 85
              puts "sending first_verifications_reminder to #{person.hbx_id}" unless Rails.env.test?
              IvlNoticesNotifierJob.perform_later(person.id.to_s, "first_verifications_reminder")
            when 70
              puts "sending second_verifications_reminder to #{person.hbx_id}" unless Rails.env.test?
              IvlNoticesNotifierJob.perform_later(person.id.to_s, "second_verifications_reminder")
            when 45
              puts "sending third_verifications_reminder to #{person.hbx_id}" unless Rails.env.test?
              IvlNoticesNotifierJob.perform_later(person.id.to_s, "third_verifications_reminder")
            when 30
              puts "sending fourth_verifications_reminder to #{person.hbx_id}" unless Rails.env.test?
              IvlNoticesNotifierJob.perform_later(person.id.to_s, "fourth_verifications_reminder")
            end
        rescue Exception => e
          Rails.logger.error {"Unable to send verification reminder notices to #{person.hbx_id} due to #{e}"}
        end
      end
    end
  end
end