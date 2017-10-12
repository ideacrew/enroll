namespace :recurring do
  desc "an automation task that sends out notifications to users"
  task ivl_reminder_notices: :environment do
    FIRST_REMINDER_TITLE = "RequestForAdditionalInformationFirstReminder"
     SECOND_REMINDER_TITLE = "RequestForAdditionalInformationSecondReminder"
     THIRD_REMINDER_TITLE = "RequestForAdditionalInformationThirdReminder"
     FOURTH_REMINDER_TITLE = "RequestForAdditionalInformationFourthReminder"
     { 90 =>85, 85 => 70, 70 => 45 , 45 => 30}.each do |previous_days, reminder_days|
      puts "reminder_days #{reminder_days}" unless Rails.env.test?
      families = Family.where({
      "households.hbx_enrollments" => {
        "$elemMatch" => {
        "aasm_state" => { "$in" => ["enrolled_contingent"] },
        } },
        "min_verification_due_date" => { "$lt"  => TimeKeeper.date_of_record + previous_days, "$gte" => TimeKeeper.date_of_record + reminder_days }
        })
      puts "families #{families.count}" unless Rails.env.test?
      families.each do |family|
        puts "family.primary_applicant.person.consumer_role.present? #{family.primary_applicant.person.consumer_role.present?}" unless Rails.env.test?
        if family.primary_applicant.person.consumer_role.present?
          enrollment = family.enrollments.order(created_at: :desc).select{|e| e.currently_active? || e.future_active?}.first
            puts " enrollment  #{enrollment.special_verification_period.present? &&  enrollment.special_verification_period >= TimeKeeper.date_of_record + reminder_days}" unless Rails.env.test?
            if enrollment
              consumer_role = family.primary_applicant.person.consumer_role
              person = family.primary_applicant.person
              begin
                case reminder_days
                  when 85 
                    puts "sending first_verifications_reminder to #{consumer_role.id}" unless (is_notice_sent?(person,FIRST_REMINDER_TITLE) || Rails.env.test?)
                    consumer_role.first_verifications_reminder unless is_notice_sent?(person,FIRST_REMINDER_TITLE)
                  when 70
                    puts "sending second_verifications_reminder to #{consumer_role.id}" unless (is_notice_sent?(person,SECOND_REMINDER_TITLE) || Rails.env.test?)
                    consumer_role.second_verifications_reminder unless is_notice_sent?(person,SECOND_REMINDER_TITLE)
                  when 45
                    puts "sending third_verifications_reminder to #{consumer_role.id}" unless (is_notice_sent?(person,THIRD_REMINDER_TITLE) || Rails.env.test?)
                    consumer_role.third_verifications_reminder unless is_notice_sent?(person,THIRD_REMINDER_TITLE) 
                  when 30
                    puts "sending fourth_verifications_reminder to #{consumer_role.id}" unless (is_notice_sent?(person,FOURTH_REMINDER_TITLE) || Rails.env.test?)
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