# Execute this command to run the script
# RAILS_ENV=production rails r script/update_magi_medicaid_monthly_household_income.rb

# NOTE: This is only a one time script for the ticket: pivotal-182598285 and cannot be used again.

require 'csv'

puts "Running data fix for taxhousehold_members magi_medicaid_monthly_household_income"

field_names = %w[family_id
                 primary_person_hbx_id
                 tax_household_group_hbx_id
                 tax_household_hbx_id
                 tax_household_member_id
                 person_hbx_id
                 before_update_magi_medicaid_monthly_household_income
                 magi_medicaid_monthly_household_income]

file_name = "#{Rails.root}/182598285_taxhousehold_members_report_after_data_fix_#{Time.new.strftime('%Y_%m_%d_%H_%M_%S')}.csv"

def fetch_families
  Family.exists(:"tax_household_groups.tax_households.tax_household_members.magi_medicaid_monthly_household_income" => true)
end

CSV.open(file_name, 'w+', headers: true) do |csv|
  csv << field_names

  fetch_families.each do |family|
    family.tax_household_groups.each do |thhg|
      thhg.tax_households.each do |thh|
        thh.tax_household_members.each do |thhm|
          next if thhm.magi_medicaid_monthly_household_income.to_f == 0.0

          before_update = thhm.magi_medicaid_monthly_household_income.to_f
          updated_value = before_update / 12

          thhm.update_attributes(magi_medicaid_monthly_household_income: updated_value)

          csv << [family.id,
                  family.primary_person.hbx_id,
                  thhg.hbx_id, thh.hbx_assigned_id,
                  thhm.id,
                  (thhm.family_member.present? ? thhm&.person&.hbx_id : 0),
                  before_update,
                  thhm&.magi_medicaid_monthly_household_income]
          print '.'
        end
      end
    end
  end
end

puts "Running data fix for applicants magi_medicaid_monthly_household_income"

field_names = %w[application_hbx_id
                 assistance_year
                 aasm_state
                 applicant_id
                 person_hbx_id
                 before_update_magi_medicaid_monthly_household_income
                 magi_medicaid_monthly_household_income]

file_name = "#{Rails.root}/182598285_applicants_report_after_data_fix_script_#{Time.new.strftime('%Y_%m_%d_%H_%M_%S')}.csv"

CSV.open(file_name, 'w+', headers: true) do |csv|
  csv << field_names

  applications = FinancialAssistance::Application.all.where(:aasm_state.nin => ["draft"], applicants: { :$elemMatch => { :magi_medicaid_monthly_household_income.exists => true, :"magi_medicaid_monthly_household_income.cents".ne => 0.0 } })

  FinancialAssistance::Application.where(:aasm_state.in => %w[determined submitted]).each do |app|
    app.applicants.each do |applicant|
      next if applicant.magi_medicaid_monthly_household_income.to_f == 0.0

      before_update = applicant.magi_medicaid_monthly_household_income.to_f
      updated_value = before_update / 12

      applicant.update_attributes(magi_medicaid_monthly_household_income: updated_value)
      csv << [app.hbx_id,
              app.assistance_year,
              app.aasm_state,
              applicant.person_hbx_id,
              before_update,
              applicant.magi_medicaid_monthly_household_income]
      print '.'
    end
  end
end
