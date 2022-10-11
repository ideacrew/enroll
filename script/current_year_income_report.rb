# frozen_string_literal: true

# For all those on applications with at least one active enrollment and a (this year) determined application, pull the member income info
# rails runner script/current_year_income_report.rb -e production
start_time = DateTime.current
puts "End of year income report start_time: #{start_time}"

year = Date.today.year
file_name = "#{Rails.root}/EOY_income_report.csv"
eligible_family_ids = ::FinancialAssistance::Application.determined.where(assistance_year: year).distinct(:family_id)
enrollments = HbxEnrollment.active.enrolled.where(:family_id.in=>eligible_family_ids)

CSV.open(file_name, 'w+', headers: true) do |csv|
  csv << ["Subscriber HBX ID", "Member HBX ID", "Member name", "Income type", "Income start date", "Income end date", "Phone number"]
  enrollments.each_with_object([]) do |enrollment, collector|
    application = ::FinancialAssistance::Application.where(family_id: enrollment.family_id, aasm_state: 'determined').max_by(&:created_at)
    next unless application

    subscriber = enrollment&.subscriber&.hbx_id
    next unless subscriber
    enrollment.hbx_enrollment_members.each do |member|
      applicant = application&.applicants(person_hbx_id: member&.hbx_id)&.first
      next unless applicant&.incomes
      applicant.incomes.each do |income|
        csv << [subscriber, member&.hbx_id, applicant&.full_name, income&.kind, income&.start_on, income&.end_on, applicant.phones&.first&.full_phone_number]
      end
    end
  rescue StandardError => e
    puts "Unable to process enrollment: #{enrollment.id}, message: #{e.message}, backtrace: #{e.backtrace}"
  end
end
end_time = DateTime.current
puts "End of year income report end_time: #{end_time}, total_time_taken_in_minutes: #{((end_time - start_time) * 24 * 60).to_f.ceil}"

