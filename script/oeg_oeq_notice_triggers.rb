# frozen_string_literal: true

# Trigger OEQ & OEG notices (to be done post-renewals)
# rails runner script/oeg_oeq_notice_triggers.rb -e production
start_time = DateTime.current
logger = Logger.new("#{Rails.root}/log/oeg_oeq_notice_triggers_#{TimeKeeper.date_of_record.strftime('%Y_%m_%d')}.log")
puts "OEQ_OEG_notice_triggers start_time: #{start_time}"
failures = 0
renewal_year = TimeKeeper.date_of_record.next_year.year

faa_application_families = ::FinancialAssistance::Application.by_year(renewal_year).distinct(:family_id)
oeg_family_ids = if EnrollRegistry.feature_enabled?(:oeg_notice_income_verification_only)
                   ::FinancialAssistance::Application.by_year(renewal_year).income_verification_extension_required.distinct(:family_id)
                 else
                   faa_application_families - ::FinancialAssistance::Application.determined.by_year(renewal_year).distinct(:family_id)
                 end
oeq_enrollments = HbxEnrollment.individual_market.active.enrolled.current_year.where(:family_id.nin=> faa_application_families).distinct(:family_id)
oeg_enrollments = HbxEnrollment.individual_market.active.enrolled.current_year.where(:family_id.in=> oeg_family_ids).distinct(:family_id)
families = oeq_enrollments + oeg_enrollments

families.each_with_index do |family_id, index|
  family = Family.find_by(id: family_id)
  next unless family.present?

  result = Operations::Notices::IvlOeReverificationTrigger.new.call(family: family)

  if result.success?
    puts "Triggered OE event for family_id: #{family_id}, index: #{index}"
    logger.info "Triggered OE event for family_id: #{family_id}, index: #{index}"
  else
    failures += 1
    puts "Error: OE event trigger for family_id: #{family_id}, index: #{index} Failed!! due to #{result.failure}"
    logger.info "Error: OE event trigger for family_id: #{family_id}, index: #{index} Failed!! due to #{result.failure}"
  end

rescue  => e
  puts "error triggering OE notice event due to #{e} for family_id #{family_id}}"
  logger.info "error triggering OE notice event due to #{e} for family_id #{family_id}}"
end
end_time = DateTime.current
puts "OEQ_OEG_notice_triggers end_time: #{end_time}, total_time_taken_in_minutes: #{((end_time - start_time) * 24 * 60).to_f.ceil}, total_number_of_failures: #{failures}"
logger.info "OEQ_OEG_notice_triggers end_time: #{end_time}, total_time_taken_in_minutes: #{((end_time - start_time) * 24 * 60).to_f.ceil}, total_number_of_failures: #{failures}"
