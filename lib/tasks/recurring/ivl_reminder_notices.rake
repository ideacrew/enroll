namespace :recurring do
  desc "an automation task that sends out notifications to users"
  task ivl_reminder_notices: :environment do
  		families_for_first_notice = Family.where({
								  "households.hbx_enrollments" => {
								    "$elemMatch" => {
								      "aasm_state" => { "$in" => ["enrolled_contingent"] },
								      "effective_on" => { "$gte" => DateTime.now + 85.days, "$lt" => 95.days }, ## will send duplucates
								      
								  } }
								}).to_a
			families_for_first_notice.each do |family| 
				#check if ivl 
				if family.primay_applicant.consumer_role.present?
						consumer_role = family.primay_applicant.consumer_role
						event_kind = ApplicationEventKind.where(:event_name => "first_verifications_reminder").first
				    notice_trigger = event_kind.notice_triggers.first
				    builder = notice_trigger.notice_builder.camelize.constantize.new(consumer_role, {
            template: notice_trigger.notice_template,
              subject: event_kind.title,
              event_name: "first_verifications_reminder",
              mpi_indicator: notice_trigger.mpi_indicator,
            }.merge(notice_trigger.notice_trigger_element_group.notice_peferences)).deliver 
      IvlNoticesNotifierJob.perform(consumer_role_id, event_name)
				end
			end
  end
end 