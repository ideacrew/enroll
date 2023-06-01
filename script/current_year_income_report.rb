# frozen_string_literal: true

# For all applicants on a current year determined application, pull the applicant income info
# rails runner script/current_year_income_report.rb -e production
start_time = DateTime.current
puts "End of year income report start_time: #{start_time}"

year = Date.today.year
file_name = "#{Rails.root}/EOY_income_report.csv"
eligible_family_ids = ::FinancialAssistance::Application.determined.where(assistance_year: year).distinct(:family_id)
families = Family.where(:id.in => eligible_family_ids)

CSV.open(file_name, 'w+', headers: true) do |csv|
  csv << ["Primary HBX ID", "Member HBX ID", "Member name", "Income/Deduction type", "Income/Deduction start date", "Income/Deduction end date", "Phone number"]
  families.each_with_object([]) do |family, collector|
    application = ::FinancialAssistance::Application.where(family_id: family.id, aasm_state: 'determined').max_by(&:created_at)
    next unless application

    primary_family_member_hbx_id = family&.primary_family_member&.hbx_id
    next unless primary_family_member_hbx_id

    application&.applicants.each do |applicant|
      next unless applicant&.incomes || applicant&.deductions
      applicant&.incomes.each do |income|
        csv << [primary_family_member_hbx_id, applicant&.person_hbx_id, applicant&.full_name, income&.kind, income&.start_on, income&.end_on, applicant.phones&.first&.full_phone_number]
      end
      next unless applicant&.deductions
      applicant.deductions.each do |deduction|
        csv << [primary_family_member_hbx_id, applicant&.person_hbx_id, applicant&.full_name, deduction&.kind, deduction&.start_on, deduction&.end_on, applicant.phones&.first&.full_phone_number]
      end
    end
  rescue StandardError => e
    puts "Unable to process family: #{family.id}, message: #{e.message}, backtrace: #{e.backtrace}"
  end
end
end_time = DateTime.current
puts "End of year income report end_time: #{end_time}, total_time_taken_in_minutes: #{((end_time - start_time) * 24 * 60).to_f.ceil}"

