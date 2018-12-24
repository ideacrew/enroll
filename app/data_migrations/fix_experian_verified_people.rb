require File.join(Rails.root, "lib/mongoid_migration_task")

class FixExperianVerifiedPeople < MongoidMigrationTask

  def migrate
    people = get_people
    people.each do |person|
      begin
        person.consumer_role.move_identity_documents_to_verified
      rescue
        $stderr.puts "Issue updating person: person #{person.id}, HBX id  #{person.hbx_id}"
      end
    end
  end

  def get_people
    user_ids = User.where("identity_final_decision_code"=> User::INTERACTIVE_IDENTITY_VERIFICATION_SUCCESS_CODE).map(&:_id)
    Person.where(:user_id.in => user_ids)
  end

end