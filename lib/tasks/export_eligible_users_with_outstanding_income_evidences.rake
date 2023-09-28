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

    days_to_extend = FinancialAssistanceRegistry[:auto_update_income_evidence_due_on].settings(:days).item
    end_range = TimeKeeper.date_of_record
    start_range = (end_range - (days_to_extend + 1).days)

    eligibile_families = Family.where(
      :eligibility_determination => { :$exists => true },
      :"eligibility_determination.outstanding_verification_status" => { :$eq => "outstanding" },
      :"eligibility_determination.outstanding_verification_earliest_due_date" => { :"$gte" => start_range, :"$lte" => end_range }
    )

    CSV.open(file_name, "w", write_headers: true, headers: field_names) do |csv|
      eligibile_families.each do |family|
        application = FinancialAssistance::Application.where(family_id: family.id).determined.max_by(&:submitted_at)
        next unless application

        applicants = get_applicants(application, start_range, end_range)
        next if applicants&.blank?

        applicants.each do |applicant|
          evidence = applicant.income_evidence
          total_extension_days = days_to_extend.days
          new_due_date = (evidence.due_on + total_extension_days)

          evidence.extend_due_on(total_extension_days, 'system', 'migration_extend_due_date') if args[:migrate_users]
          successful_save = (evidence.due_on == new_due_date)

          csv << populate_csv_row(family, applicant, new_due_date, successful_save)
        rescue StandardError => e
          puts "Invalid Applicant for Application with hbx_id #{application&.hbx_id}, Applicant person_hbx_id #{applicant&.person_hbx_id}: #{e.message}"
        end

      rescue StandardError => e
        puts "An error occurred while processing an application with hbx_id #{application&.hbx_id}: #{e.message}"
      end
    end

    puts "Generates a report of all applicants with income evidences eligible for an extension"
  end
end

def get_applicants(application, start_range, end_range)
  valid_aasm_states = ['outstanding', 'rejected']

  application.applicants.select do |applicant|
    evidence = applicant.income_evidence

    # NOTE: this line is rubocop's fault
    puts "Income evidence missing date: Application #{application.hbx_id}, Applicant #{applicant.person_hbx_id}, Income Evidence: #{evidence.id}, state: #{evidence.aasm_state}" if evidence&.due_on&.blank?

    evidence&.due_on &&
      valid_aasm_states.include?(evidence&.aasm_state) &&
      (evidence.due_on >= start_range && evidence.due_on <= end_range) &&
      evidence.can_be_extended?('migration_extend_due_date')
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
    (successful_save ? 'TRUE' : 'NOT EXTENDED')
  ]
end