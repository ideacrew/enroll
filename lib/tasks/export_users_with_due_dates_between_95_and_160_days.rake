require 'csv'
# This report generates list of all the employers with the new hire eligiblity rule as "date_of_hire" for 2016 plan year.
#RAILS_ENV=production bundle exec rake reports:export_users_with_due_dates_between_95_and_160_days
namespace :reports do
  task :export_users_with_due_dates_between_95_and_160_days => :environment do
    # All families w/active enrollments for current_year
    # families = Family.by_enrollment_individual_market.where(
    # :"_id".in => HbxEnrollment.where(
    #   aasm_state: "coverage_selected",
    #   effective_on: { :"$gte" => TimeKeeper.date_of_record.beginning_of_year, :"$lte" =>  TimeKeeper.date_of_record.end_of_year }
    #   ).pluck(:family_id))
    # binding.irb
    today = TimeKeeper.date_of_record
    applications = FinancialAssistance::Application.where(
      :"applicants.income_evidence" => {:$exists => true},
      :"applicants.income_evidence.aasm_state" => {:$eq => "outstanding"},
      :"applicants.income_evidence.due_on" => {
        :"$gt" => (today - 160.days), 
        :"$lte" =>  (today - 95.days)
      }
    )
    # FinancialAssistance::Application.where(:"applicants.income_evidence" => {:$exists => true}, :"applicants.income_evidence.due_on" => {:"$gte" => (TimeKeeper.date_of_record.end_of_year - 159.days), :"$lte" =>  (TimeKeeper.date_of_record.end_of_year - 95.days) })
    binding.irb

    applications.each do |application|
      binding.irb
      applicant_data = determine_applicant_update_data(application, today)
      binding.irb
    end

    

    # field_names  = [
    #   :user_hbx_id,
    #   :original_due_date,
    #   :due_date_after_extension,
    #   :due_date_successfully_extended,
    #   :family_level_due_date
    # ]

    # file_name = "#{Rails.root}/public/users_with_outstanding_income_evidence_due_dates_between_95_and_160_days.csv"

    # CSV.open(file_name, "w", write_headers: true, headers: field_names) do |csv|
    #   array_of_applicants.each do |user|
    #     begin
    #       # if operation is for data_migration (not just report), update income evidence to new due_date
    #       # check if current_due_date == due_date_after extension
    #       # evidence = user.income_evidence
    #       # update_status = (evidence.current_due_date == due_date_after_extension) ? 'success' : 'failure'
    #       csv << [ user.person_hbx_id, evidence.due_date, due_date_after_extension, update_status, family_level_due_date ]
    #     rescue StandardError => e
    #       puts "an error occurred while creating csv: #{e.message}"
    #     end
    #   end
    #   puts "Generates a report of all employers with new hire eligiblity rule as date of hire"
    # end
  end
end

def determine_applicant_update_data(application, today)
  applicant_info = application.applicants.map do |applicant|
    evidence = applicant.income_evidence
    binding.irb
    # get direct evidences...
    next unless evidence &&
      evidence.aasm_state == 'outstanding' &&
      (evidence.due_on >= today - 160.days && evidence.due_on <= today - 95.days)

    days_from_today = (today - evidence.due_on).to_i
    days_extended = (160 - days_from_today)
    new_due_date = (today + days_extended.days)

    # Use TimeKeeper here?
    # evidence.update(due_on: new_due_date)
    # then do a bunch of other stuff

    # current family.min

    { 
      hbx_id: applicant.person_hbx_id, 
      original_due_date: evidence.due_on,
      due_date_after_extension: new_due_date,
      due_date_successfully_extended: (evidence.due_on == new_due_date)
    }
    binding.irb
  end
  binding.irb

  family_min_due_date = application.family.min_verification_due_date_on_family
  applicant_info.each { |info| info[:family_level_due_date] = family_min_due_date }
  # Family level due date for all evidences or just income evidences?
end

# A select amount of existing users that are between 95 days and 159 days that have outstanding evidences will be extended to a maximum of 160 days.
# Applicant.where(evidences[:evidence_types] => aasm_state: 'outstanding')

# Operation should also update family level due date to the closest due date of any of the dependents. 

# After extending due date for evidence, check 
# family.min_verification_due_date_on_family
# family.eligibility_determination.update(outstanding_verification_earliest_due_date: applicants_earliest_due_date)
