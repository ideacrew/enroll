namespace :migrations do

  desc "IVL policy end date update"
  task :ivl_policy_end_date_update => :environment do
    CSV.foreach("public/ivl_policy.csv", headers: true) do |row|
      policy = row.to_hash
      hbx_id = policy["Policy ID"].to_s
      termination_date = policy["UPDATED END DATE"]
      terminated_on = Date.strptime(termination_date.to_s, "%m/%d/%y")
      enrollment = HbxEnrollment.by_hbx_id(hbx_id)
      next unless enrollment.size == 1
      if enrollment.first.effective_on < terminated_on
         enrollment.first.workflow_state_transitions << WorkflowStateTransition.new(
                                                       from_state: enrollment.first.aasm_state,
                                                       to_state: "coverage_terminated"
                                                       )
         enrollment.first.update_attributes(aasm_state: "coverage_terminated")
         enrollment.first.update_attributes(terminated_on: terminated_on)
      elsif enrollment.first.effective_on == terminated_on
        if enrollment.first.aasm_state != "coverage_canceled"
          enrollment.first.workflow_state_transitions << WorkflowStateTransition.new(
              from_state: enrollment.first.aasm_state,
              to_state: "coverage_canceled"
          )
          enrollment.first.update_attributes(aasm_state: "coverage_canceled")
        end
      else
        puts "Termination date should not be earlier than effective on date for enrollment #{hbx_id}" unless Rails.env.test?
      end
    end
  end
end






