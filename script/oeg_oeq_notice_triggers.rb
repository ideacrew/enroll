# frozen_string_literal: true

# Trigger OEQ & OEG notices (to be done post-renewals)
# rails runner script/oeg_oeq_notice_triggers.rb -e production
start_time = DateTime.current
puts "OEQ_OEG_notice_triggers start_time: #{start_time}"
failures = 0
renewal_year = TimeKeeper.date_of_record.next_year.year

determined_applications = ::FinancialAssistance::Application.determined.by_year(renewal_year).distinct(:family_id)
faa_application_families = ::FinancialAssistance::Application.by_year(renewal_year).distinct(:family_id)
oeq_enrollments = HbxEnrollment.active.enrolled.current_year.where(:family_id.nin=>faa_application_families).distinct(:family_id)
oeg_enrollments = HbxEnrollment.active.enrolled.current_year.where(:family_id.in=>(faa_application_families-determined_applications)).distinct(:family_id)
families = oeq_enrollments + oeg_enrollments

families.each_with_index do |family_id, index|
  family = Family.find_by(id: family_id)
  next unless family.present?

  result = Operations::Notices::IvlOeReverificationTrigger.new.call(family: family)

  if result.success?
    puts "Triggered OE event for family_id: #{family_id}, index: #{index}"
  else
    failures += 1
    puts "Error: OE event trigger for family_id: #{family_id}, index: #{index} Failed!! due to #{result.failure}"
  end

rescue  => e
  puts "error triggering OE notice event due to #{e} for family_id #{family_id}}"
end
end_time = DateTime.current
puts "OEQ_OEG_notice_triggers end_time: #{end_time}, total_time_taken_in_minutes: #{((end_time - start_time) * 24 * 60).to_f.ceil}, total_number_of_failures: #{failures}"