namespace :migrations do

  desc "IVL policy end date update"
  task :ivl_policy_end_date_update => :environment do
    CSV.foreach("public/ivl_policy.csv", headers: true) do |row|
      policy = row.to_hash
      hbx_id = policy["Policy ID"]
      termination_date = policy["UPDATED END DATE"]
      terminated_on = Date.strptime(termination_date.to_s, "%m/%d/%Y")
      puts [hbx_id, terminated_on]
      enrollment = HbxEnrollment.by_hbx_id(hbx_id)
      next unless enrollment.size == 1
      enrollment.first.update_attributes(terminated_on: terminated_on)
    end
  end
end






