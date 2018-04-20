namespace :migrations do

  desc "IVL policy end date update"
  task :ivl_policy_end_date_update => :environment do
    CSV.foreach("public/ivl_policy.csv", headers: true) do |row|
      policy = row.to_hash
      hbx_id = policy["Policy ID"].to_s
      termination_date = policy["UPDATED END DATE"]
      terminated_on = Date.strptime(termination_date.to_s, "%m/%d/%y")
      enrollment = HbxEnrollment.by_hbx_id(hbx_id).first
      next if enrollment.blank?
      enrollment_state = enrollment.aasm_state
      if enrollment.effective_on < terminated_on
        enrollment.update_attributes(aasm_state: "coverage_terminated", terminated_on: terminated_on)
        # comment out to force silent update out of enroll
        # enrollment.workflow_state_transitions.create({from_state: enrollment_state, to_state: "coverage_terminated"})
      elsif enrollment.effective_on == terminated_on
        if !enrollment.coverage_canceled?
          enrollment.update_attributes(aasm_state: "coverage_canceled")
          # comment out to force silent update out of enroll
          # enrollment.workflow_state_transitions.create({from_state: enrollment_state, to_state: "coverage_canceled"})
        end
      else
        puts "Termination date should not be earlier than effective on date for enrollment #{hbx_id}" unless Rails.env.test?
      end
    end
  end
end






