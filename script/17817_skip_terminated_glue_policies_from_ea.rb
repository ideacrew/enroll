require 'csv'

glue_file_name = "10655_export_glue_multi_row_sep_16_cancelled_08_29.csv"
enroll_file_name = "ea_uqhp_data_export_ivl_pre_08_29_2018.csv"
# csv_match = CSV.open("matching_data_that_exists_in_ea_based_on_glue_report#{TimeKeeper.date_of_record.strftime('%m_%d_%Y')}.csv", "w")
# csv_match << %w(family.id policy.id policy.subscriber.coverage_start_on policy.aasm_state policy.plan.coverage_kind policy.plan.metal_level  policy.plan.name policy.subscriber.person.hbx_id policy.subscriber.person.is_incarcerated  policy.subscriber.person.citizen_status policy.subscriber.person.is_dc_resident?  is_dependent)
# csv_mismatch = CSV.open("mismatching_data_that_doesnt_exist_in_ea_based_on_glue_report#{TimeKeeper.date_of_record.strftime('%m_%d_%Y')}.csv", "w")
# csv_mismatch << %w(family.id  policy.id policy.subscriber.coverage_start_on policy.aasm_state policy.plan.coverage_kind policy.plan.metal_level  policy.plan.name policy.subscriber.person.hbx_id policy.subscriber.person.is_incarcerated  policy.subscriber.person.citizen_status policy.subscriber.person.is_dc_resident?  is_dependent)

csv_glue_minus_ea = CSV.open("matching_data_that_exists_in_ea_based_on_glue_report#{TimeKeeper.date_of_record.strftime('%m_%d_%Y')}.csv", "w")
csv_glue_minus_ea << %w(family.id policy.id policy.subscriber.coverage_start_on policy.aasm_state policy.plan.coverage_kind policy.plan.metal_level  policy.plan.name policy.subscriber.person.hbx_id policy.subscriber.person.is_incarcerated  policy.subscriber.person.citizen_status policy.subscriber.person.is_dc_resident?  is_dependent)

csv_ea_minus_glue = CSV.open("matching_data_that_exists_in_ea_based_on_glue_report#{TimeKeeper.date_of_record.strftime('%m_%d_%Y')}.csv", "w")
csv_ea_minus_glue << %w(family.id policy.id policy.subscriber.coverage_start_on policy.aasm_state policy.plan.coverage_kind policy.plan.metal_level  policy.plan.name policy.subscriber.person.hbx_id policy.subscriber.person.is_incarcerated  policy.subscriber.person.citizen_status policy.subscriber.person.is_dc_resident?  is_dependent)

@terminated_glue_keys = CSV.foreach(glue_file_name,:headers =>true).inject([]) do |terminated_glue_keys, r|
  terminated_glue_keys << ((r["policy.eg_id"]+"_"+r["person.authority_member_id"]) rescue nil)
end

@terminated_glue_keys.flatten!
@terminated_glue_keys.compact!

@terminated_ea_keys = CSV.foreach(enroll_file_name,:headers =>true).inject([]) do |terminated_ea_keys, r|
  terminated_ea_keys << ((r["policy.id"]+"_"+r["policy.subscriber.person.hbx_id"]) rescue nil)
end

@terminated_ea_keys.flatten!
@terminated_ea_keys.compact!

CSV.foreach(glue_file_name,:headers =>true).each do |row|
  test_string = ((row["policy.eg_id"]+"_"+row["person.authority_member_id"]) rescue nil)
  if !(test_string && @terminated_ea_keys.include?(test_string))
    csv_glue_minus_ea.add_row(row)
  end
end

CSV.foreach(enroll_file_name,:headers =>true).each do |row|
  test_string = ((row["policy.id"]+"_"+row["policy.subscriber.person.hbx_id"]) rescue nil)
  if !(test_string && @terminated_ea_keys.include?(test_string))
    csv_ea_minus_glue.add_row(row)
  end
end
