require File.join(Rails.root, "lib/mongoid_migration_task")

class FixCitizenStatus < MongoidMigrationTask

  def get_people
    Person.where({ :"consumer_role" => {"$exists" => true},
        :"consumer_role.aasm_state"=>"fully_verified",
        :"consumer_role.lawful_presence_determination.citizen_status" => {'$in' => ConsumerRole::INELIGIBLE_CITIZEN_VERIFICATION} })
  end

  def migrate
    people = get_people
    people.each do |person|
      begin
        update_citizen_status_not_lawfully_present(person)
      rescue
        $stderr.puts "Issue migrating person: person #{person.id}, HBX id  #{person.hbx_id}"
      end
    end
  end

  def update_citizen_status_not_lawfully_present(person)
    old_status = person.citizen_status
    if person.verification_types.active.map(&:type_name).include? 'Immigration status'
      lpd(person).update_attributes!(:citizen_status => "alien_lawfully_present")
      puts "Person HBX_ID: #{person.hbx_id} citizen status was changed from #{old_status} to ==> #{person.citizen_status}" unless Rails.env.test?
    end
  end

  def lpd(person)
    person.try(:consumer_role).try(:lawful_presence_determination)
  end

end
