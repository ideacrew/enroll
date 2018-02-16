require 'csv'

csv_glue = CSV.read("/Users/Varun/Desktop/reports/proj_elig_notice_1/17817_export_glue_multi_row_08_29_2017.csv", :headers => true)
csv_ea = CSV.read("/Users/Varun/Desktop/reports/proj_elig_notice_1/17817_export_ea_08_23_2017.csv", :headers => true)

csv_match = CSV.open("glue_canceled_and_terminated_poilices_#{TimeKeeper.date_of_record.strftime('%m_%d_%Y')}.csv", "w")
csv_match << %w(family.id policy.id policy.subscriber.coverage_start_on policy.aasm_state policy.plan.coverage_kind policy.plan.metal_level  policy.plan.name policy.subscriber.person.hbx_id policy.subscriber.person.is_incarcerated  policy.subscriber.person.citizen_status policy.subscriber.person.is_dc_resident?  is_dependent)

csv_mismatch = CSV.open("final_ea_report_#{TimeKeeper.date_of_record.strftime('%m_%d_%Y')}.csv", "w")
csv_mismatch << %w(family.id  policy.id policy.subscriber.coverage_start_on policy.aasm_state policy.plan.coverage_kind policy.plan.metal_level  policy.plan.name policy.subscriber.person.hbx_id policy.subscriber.person.is_incarcerated  policy.subscriber.person.citizen_status policy.subscriber.person.is_dc_resident?  is_dependent)

terminated_glue_keys = csv_glue.select do |row|
  row["policy.aasm_state"].downcase == 'terminated' || row["policy.aasm_state"].downcase == 'canceled'
end.flat_map{|r| r["policy.eg_id"]+"_"+r["person.authority_member_id"] }

csv_ea.each do |row|
  if terminated_glue_keys.include?(row["policy.id"]+"_"+row["policy.subscriber.person.hbx_id"])
    csv_match.add_row(row)
  else
    csv_mismatch.add_row(row)
  end
end