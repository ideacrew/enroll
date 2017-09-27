require File.join(Rails.root, "lib/mongoid_migration_task")

class DisregardTerminationOfCoverageNotice < MongoidMigrationTask
  def migrate
    def create_secure_inbox_message_for_employer(employer_profile)
      body = "Your employees should please disregard the notice that they received on 9/26/2017 stating that their employer was not offering health coverage through the Massachusetts Health Connector. This notice was sent in error. We apologize for any inconvenience this may have caused."+ 
        "<br><br>Your employees have received a correction message clarifying that their employer has completed its open enrollment period and has successfully met all eligibility requirements. It also confirms that the employees plan selection, if any, will go into effect on the coverage effective date shown in your account."+ 
        "<br><br>Thank you for enrolling into employer-sponsored coverage through the Health Connector." + 
        "<br><br> If you have any questions, please call 1-888-813-9220 (TTY: 711), press option 1."
      subject = "Disregard Termination of Coverage Notice"
      message = employer_profile.inbox.messages.build({ subject: subject, body: body, from: "MA Health Connector"})
      message.save!
    end

    feins = ["261813097", "204560412", "821100214", "263082892"]

    feins.each do |fein|
      begin
        org = Organization.where(:fein => fein).first
        create_secure_inbox_message_for_employer(org.employer_profile)
      rescue => e
        puts "Unable to find Organization with FEIN #{fein}, due to -- #{e}" unless Rails.env.test?
      end
    end

    def create_secure_inbox_message_for_employee(person)
      body = "Please disregard the notice that you received on 9/26/2017 stating that your employer was not offering health coverage through the Massachusetts Health Connector. This notice was sent in error. We apologize for any inconvenience this may have caused." +
       "<br><br>Your employer has completed its open enrollment period and has successfully met all eligibility requirements." + 
       "<br><br>Your plan selection, if any, will go into effect on the coverage effective date shown in your account." +
       "<br><br>Thank you for enrolling into employer-sponsored coverage through the Health Connector."+ 
       "<br> <br>If you have any questions, please call 1-888-813-9220 (TTY: 711), press option 1."
      subject = "Disregard Termination of Coverage Notice"
      message = person.inbox.messages.build({ subject: subject, body: body, from: "MA Health Connector"})
      message.save!
    end

    hbx_ids = ["100239", "100126", "100164", "100228", "100189", "100201", "100220", "100190", "100191", "100077", "100234","100204", "100202", "100238", "100226", "100211", "100206", "100218"]
    hbx_ids.each do |hbx_id|
      begin
        person = Person.where(:hbx_id => hbx_id).first
        create_secure_inbox_message_for_employee(person)
      rescue => e
        puts "Unable to find employee with hbx_id #{hbx_id}, due to -- #{e}" unless Rails.env.test?
      end
    end
  end
end