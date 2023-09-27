# frozen_string_literal: true

require 'csv'
# This report generates list of all the applicants with outstanding income evidences between 95 and 160 days

# To generate a csv of users eligible for an income evidence due_on extension without migrating data, run the following:
# RAILS_ENV=production bundle exec rake reports:export_eligible_users_with_outstanding_income_evidences

# To migrate eligible users' income evidences due_on to their new due date, run the following:
# RAILS_ENV=production bundle exec rake reports:export_eligible_users_with_outstanding_income_evidences[true]

# The CSV file generated will be called users_with_outstanding_income_evidence_eligible_for_extension.csv, and will be located in the root folder

namespace :reports do
  task :export_eligible_users_with_outstanding_income_evidences, [:migrate_users] => :environment do |_t, args|
    file_name = "#{Rails.root}/users_with_outstanding_income_evidence_eligible_for_extension.csv"
    field_names  = [
      :primary_applicant_hbx_id,
      :family_eligibility_determination_outstanding_verification_status,
      :family_eligibility_determination_outstanding_verification_earliest_due_date,
      :family_eligibility_determination_outstanding_verification_document_status,
      :application_hbx_id,
      :application_assistance_year,
      :application_submitted_at,
      :application_aasm_state,
      :applicant_person_hbx_id,
      :income_evidence_bson_id,
      :income_evidence_existing_due_date,
      :income_evidence_new_due_date,
      :due_date_successfully_extended
    ]

    days_to_extend = (FinancialAssistanceRegistry[:auto_update_income_evidence_due_on].settings(:days).item + 1)
    end_range = TimeKeeper.date_of_record
    start_range = (end_range - days_to_extend.days)

    eligibile_families = Family.where(
      :eligibility_determination => { :$exists => true },
      :"eligibility_determination.outstanding_verification_status" => { :$eq => "outstanding" },
      :"eligibility_determination.outstanding_verification_earliest_due_date" => { :"$gte" => start_range, :"$lte" => end_range }
    )

    CSV.open(file_name, "w", write_headers: true, headers: field_names) do |csv|
      eligibile_families.each do |family|
        application = FinancialAssistance::Application.where(family_id: family.id).determined.max_by(&:submitted_at)

        application.applicants.each do |applicant|
          evidence = applicant&.income_evidence

          next unless evidence &&
                      ['outstanding', 'rejected'].include?(evidence.aasm_state) &&
                      # evidence.aasm_state == 'outstanding' &&
                      (evidence.due_on >= start_range && evidence.due_on <= end_range)

          original_due_date = (evidence.due_on - 95.days)
          new_due_date = (original_due_date + 160.days)
          successful_save = evidence.update(due_on: new_due_date) if args[:migrate_users]

          csv << populate_csv_row(family, applicant, new_due_date, successful_save)
        rescue StandardError => e
          puts "Invalid Applicant for Application with hbx_id #{application&.hbx_id}, Applicant person_hbx_id #{applicant&.person_hbx_id}: #{e.message}"
        end

        update_family_level_due_date_info(application.family)
      rescue StandardError => e
        puts "An error occurred while processing an application with hbx_id #{application&.hbx_id}: #{e.message}"
      end
    end

    puts "Generates a report of all applicants with income evidences eligible for an extension"
  end
end

def populate_csv_row(family, applicant, new_due_date, successful_save)
  ed = family.eligibility_determination
  application = applicant.application
  evidence = applicant.income_evidence

  [
    application.primary_applicant.person_hbx_id,
    ed.outstanding_verification_status,
    ed.outstanding_verification_earliest_due_date,
    ed.outstanding_verification_document_status,
    application.hbx_id,
    application.assistance_year,
    application.submitted_at,
    application.aasm_state,
    applicant.person_hbx_id,
    evidence.id,
    evidence.due_on,
    new_due_date,
    (successful_save ? _ : 'NOT EXTENDED')
  ]
end
