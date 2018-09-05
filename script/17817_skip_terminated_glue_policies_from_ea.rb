require 'csv'

csv_glue = CSV.read("#{Rails.root}//10655_export_glue_multi_row_sep_16_cancelled.csv", :headers => true)
csv_ea = CSV.read("#{Rails.root}//ea_uqhp_data_export_ivl_pre_09_05_2018.csv", :headers => true)

csv_match = CSV.open("final_ea_list_with_active_coverage_in_glue_#{TimeKeeper.date_of_record.strftime('%m_%d_%Y')}.csv", "w")
csv_match << %w(family.id policy.id policy.subscriber.coverage_start_on policy.aasm_state policy.plan.coverage_kind policy.plan.metal_level  policy.plan.name policy.subscriber.person.hbx_id policy.subscriber.person.is_incarcerated  policy.subscriber.person.citizen_status policy.subscriber.person.is_dc_resident?  is_dependent)

csv_mismatch = CSV.open("ea_list_with_no_active_coverage_in_glue_#{TimeKeeper.date_of_record.strftime('%m_%d_%Y')}.csv", "w")
csv_mismatch << %w(family.id  policy.id policy.subscriber.coverage_start_on policy.aasm_state policy.plan.coverage_kind policy.plan.metal_level  policy.plan.name policy.subscriber.person.hbx_id policy.subscriber.person.is_incarcerated  policy.subscriber.person.citizen_status policy.subscriber.person.is_dc_resident?  is_dependent)

glue_keys = csv_glue.flat_map{|r| r["policy.eg_id"]+"_"+r["person.authority_member_id"] }

csv_ea.each do |row|
  next if ["shopping", "coverage_canceled", "coverage_terminated"].include?(row["policy.aasm_state"]) # Skip enrollments which are not active in EA's list.
  if glue_keys.include?(row["policy.id"]+"_"+row["policy.subscriber.person.hbx_id"])
    csv_match.add_row(row)
  else
    csv_mismatch.add_row(row)
  end
end
