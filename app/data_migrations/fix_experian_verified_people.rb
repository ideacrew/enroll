require File.join(Rails.root, "lib/mongoid_migration_task")

class FixExperianVerifiedPeople < MongoidMigrationTask

  def migrate
    people = get_people
    people.each do |person|
      begin
        move_identity_to_verified(person)
      rescue
        $stderr.puts "Issue updating person: person #{person.id}, HBX id  #{person.hbx_id}"
      end
    end
  end

  def move_identity_to_verified(person)
     person.consumer_role.update_attributes(identity_validation: 'valid', application_validation: 'valid',
                                            identity_update_reason: 'Verified by Experian', application_update_reason: 'Verified by Experian') if person.has_consumer_role?
  end


  def get_people
    user_ids = User.where("identity_response_code"=> User::INTERACTIVE_IDENTITY_VERIFICATION_SUCCESS_CODE).map(&:_id)
    Person.where(:user_id.in => user_ids)
  end

end