namespace :recurring do
  desc "an automation task that sends out notifications to users"
  task ivl_reminder_notices: :environment do
  	 FIRST_REMINDER_TITLE = "Request for Additional Information - First Reminder"
  	 SECOND_REMINDER_TITLE = "Request for Additional Information - Second Reminder"
  	 THIRD_REMINDER_TITLE = "Request for Additional Information - Third Reminder"
  	 FOURTH_REMINDER_TITLE = "Request for Additional Information - Fourth Reminder"

  		families_for_first_notice = Family.where({
								  "households.hbx_enrollments" => {
								    "$elemMatch" => {
								      "aasm_state" => { "$in" => ["enrolled_contingent"] },
								      "effective_on" => { "$gte" => 100.days }
								  } }
								}).to_a
			families_for_first_notice.each do |family|
				if family.primay_applicant.person.consumer_role.present?
					enrollment = family.enrollments.order(created_at: :desc).select{|e| e.currently_active? || e.future_active?}.first
        	[85,70,45,30].each do |reminder_days|
					if enrollment.special_verification_period.present? && 
						enrollment.special_verification_period >= DateTime.now + reminder_days
            consumer_role = family.primary_applicant.person.consumer_role
            primary_applicant = family.primary_applicant
            begin
              case reminder_days
                when 85
                  consumer_role.first_verifications_reminder unless is_notice_sent?(primary_applicant,FIRST_REMINDER_TITLE)
                when 70
                  consumer_role.second_verifications_reminder unless is_notice_sent?(primary_applicant,SECOND_REMINDER_TITLE)
                when 45
                  consumer_role.third_verifications_reminder unless is_notice_sent?(primary_applicant,THIRD_REMINDER_TITLE)
                when 30
                  consumer_role.fourth_verifications_reminder unless is_notice_sent?(primary_applicant,FOURTH_REMINDER_TITLE)
            rescue Exception => e
              Rails.logger.error e.to_s
            end
          end
        end
      end

						#special_verification_period
						# consumer_role = family.primay_applicant.consumer_role
						# event_kind = ApplicationEventKind.where(:event_name => "first_verifications_reminder").first
				  #   notice_trigger = event_kind.notice_triggers.first
				  #   builder = notice_trigger.notice_builder.camelize.constantize.new(consumer_role, {
      #       template: notice_trigger.notice_template,
      #         subject: event_kind.title,
      #         event_name: "first_verifications_reminder",
      #         mpi_indicator: notice_trigger.mpi_indicator,
      #       }.merge(notice_trigger.notice_trigger_element_group.notice_peferences)).deliver 
      			# IvlNoticesNotifierJob.perform(consumer_role_id, event_name)
				end
			end
  end

  def is_notice_sent?(person,document_title)
  	person.documents.detect{|d| d.title == document_title }
  end
end 