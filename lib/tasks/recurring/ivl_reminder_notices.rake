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
								      "effective_on" => { "$gte" => TimeKeeper.date_of_record + 100.days },
								  } }
								}).to_a
			families_for_first_notice.each do |family|
				if family.primary_applicant.person.consumer_role.present?
					enrollment = family.enrollments.order(created_at: :desc).select{|e| e.currently_active? || e.future_active?}.first
        	[85,70,45,30].each do |reminder_days|
					if enrollment.special_verification_period.present? && 
						enrollment.special_verification_period >= DateTime.now + reminder_days
            consumer_role = family.primary_applicant.person.consumer_role
            person = family.primary_applicant.person
            begin
              case reminder_days
                when 85
                  consumer_role.first_verifications_reminder unless is_notice_sent?(person,FIRST_REMINDER_TITLE)
                when 70
                  consumer_role.second_verifications_reminder unless is_notice_sent?(person,SECOND_REMINDER_TITLE)
                when 45
                  consumer_role.third_verifications_reminder unless is_notice_sent?(person,THIRD_REMINDER_TITLE)
                when 30
                  consumer_role.fourth_verifications_reminder unless is_notice_sent?(person,FOURTH_REMINDER_TITLE)
                end
            rescue Exception => e
              Rails.logger.error e.to_s
            end
          end
        end
      end
		end
  end

  def is_notice_sent?(person,document_title)
  	person.documents.detect{|d| d.title == document_title }
  end
end 