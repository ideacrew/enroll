require File.join(Rails.root, "lib/mongoid_migration_task")

class RemoveResidentRole < MongoidMigrationTask

  # this script will remove the resident role from any person who is not in the
  # explicit list of people who should have received the resident role and have a
  # corresponding coverall enrollment. For people not in this group this rake task
  # will remove the resident role and fix any enrollments associated with that person
  # designated as coverall.

  def migrate
    correct_assignments = ['58b71497f1244e4a42000095', '572a6491f1244e025a00007f',
      '58b9d9da082e7653ea000106', '58e3dc7d50526c33c5000187']
    people = Person.where("resident_role" => {"$exists" => true, "$ne" => nil})
    people.each do |person|
      # exclude the valid coverall enrollments
      unless correct_assignments.include?(person.id.to_s)
        person.primary_family && person.primary_family.active_household.hbx_enrollments.each do |enrollment|
          # indicates enrollment needs to be fixed as well
          if enrollment.kind == "coverall"
            enrollment.kind = "individual"
            if person.consumer_role.nil?
              clone_resident_role(person.resident_role)
              enrollment.consumer_role_id = person.consumer_role.id
              enrollment.resident_role_id = nil
            end
            enrollment.save!
          end
          person.resident_role.destroy
          puts "removed resident role for Person: #{person.hbx_id}" unless Rails.env.test?
        end
      end
    end
  end

  def clone_resident_role(r_role)
    c_role = ConsumerRole.new
    c_role.is_applicant = r_role.is_applicant
    c_role.is_active = r_role.is_active
    c_role.bookmark_url = r_role.bookmark_url
    c_role.is_state_resident = r_role.is_state_resident
    c_role.residency_determined_at = r_role.residency_determined_at
    c_role.contact_method = r_role.contact_method
    c_role.language_preference = r_role.language_preference
    c_role.lawful_presence_determination = r_role.lawful_presence_determination
    c_role.documents = r_role.paper_applications
    c_role.person = r_role.person
    c_role.save!
  end
end