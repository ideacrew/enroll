# frozen_string_literal: true

require 'csv'
# This report generates list of all the applicants with outstanding income evidences between 95 and 160 days

# To generate a csv of users eligible for an income evidence due_on extension without migrating data, run the following:
# RAILS_ENV=production bundle exec rake reports:export_eligible_users_with_outstanding_income_evidences

# To migrate eligible users' income evidences due_on to their new due date, run the following:
# RAILS_ENV=production bundle exec rake reports:export_eligible_users_with_outstanding_income_evidences[true]

# The CSV file generated will be called users_with_outstanding_income_evidence_due_dates_between_95_and_160_days.csv, and will be located in the root folder

namespace :reports do
  task :export_eligible_users_with_outstanding_income_evidences, [:migrate_users] => :environment do |_t, args|
    file_name = "#{Rails.root}/users_with_outstanding_income_evidence_due_dates_between_95_and_160_days.csv"
    today = TimeKeeper.date_of_record

    field_names  = [
      :user_hbx_id,
      :original_due_date,
      :due_date_after_extension,
      :due_date_successfully_extended
    ]

    applications = FinancialAssistance::Application.where(
      :"applicants.income_evidence" => { :$exists => true },
      :"applicants.income_evidence.aasm_state" => { :$eq => "outstanding" },
      :"applicants.income_evidence.due_on" => { :"$gt" => (today - 160.days), :"$lte" => (today - 95.days) }
    )

    CSV.open(file_name, "w", write_headers: true, headers: field_names) do |csv|
      applications.each do |application|
        application.applicants.each do |applicant|
          evidence = applicant&.income_evidence

          next unless evidence &&
                      evidence&.aasm_state == 'outstanding' &&
                      (evidence&.due_on > today - 160.days && evidence&.due_on <= today - 95.days)

          original_due_date = evidence.due_on
          new_due_date = (original_due_date + 160.days)
          successful_save = evidence.update(due_on: new_due_date) if args[:migrate_users]

          csv << [applicant.person_hbx_id, original_due_date, new_due_date, successful_save]

        rescue StandardError => e
          puts "Invalid Applicant for Application with hbx_id #{application.hbx_id}: #{e.message}"
        end

        update_family_level_due_date_info(application.family)
      rescue StandardError => e
        puts "An error occurred while processing an application: #{e.message}"
      end
    end

    puts "Generates a report of all applicants with income evidences eligible for an extension"
  end
end

def update_family_level_due_date_info(family)
  ed = family&.eligibility_determination
  return puts("Family Object with ID #{family.id.to_s} missing Eligibility Determination") unless ed

  min_due_date = family&.min_verification_due_date_on_family
  current_ed_outstanding_due_date = ed&.outstanding_verification_earliest_due_date
  return unless min_due_date && current_ed_outstanding_due_date

  ed.update(outstanding_verification_earliest_due_date: min_due_date) if min_due_date > current_ed_outstanding_due_date
end
