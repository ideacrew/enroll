require File.join(Rails.root, "lib/mongoid_migration_task")

class RemoveResidentRole < MongoidMigrationTask

  # this script will remove the resident role from any person who is not in the
  # explicit list of people who should have received the resident role and have a
  # corresponding coverall enrollment. For people not in this group this rake task
  # will remove the resident role and fix any enrollments associated with that person
  # designated as coverall.

  def migrate
    correct_assignments = ENV['coverall_ids'].to_s.split(',')
    # using the p_to_fix_id variable to test individual cases before running on the entire system
    if ENV['p_to_fix_id'].nil?
      people = Person.where("resident_role" => {"$exists" => true, "$ne" => nil})
    else
      people = Person.where(id: ENV['p_to_fix_id'].to_s).first
    end
    people.each do |person|
      # exclude the valid coverall enrollments
      unless correct_assignments.include?(person.id.to_s)
        person.primary_family && person.primary_family.active_household.hbx_enrollments.each do |enrollment|
          # indicates enrollment needs to be fixed as well
          if enrollment.kind == "coverall"
            enrollment.kind = "individual"
            # check for all members on enrollment to remove all resident roles
            if enrollment.hbx_enrollment_members.size > 1
              enrollment_members = get_members_as_people_for_enrollment(enrollment.hbx_id)
              enrollment_members.each do |member|
                if member.consumer_role.nil?
                  copy_resident_role_to_consumer_role(member.resident_role)
                end
                member.resident_role.destroy
              end
              enrollment.consumer_role_id = person.consumer_role.id
              enrollment.resident_role_id = nil
            elsif person.consumer_role.nil?
              copy_resident_role_to_consumer_role(person.resident_role)
              enrollment.consumer_role_id = person.consumer_role.id
              enrollment.resident_role_id = nil
            end
            enrollment.save!
          end
          # this will already be done if there are multiple members on the enrollment
          person.resident_role.destroy if enrollment.hbx_enrollment_members.size == 1
          puts "removed resident role for Person: #{person.hbx_id}" unless Rails.env.test?
        end
      end
    end
  end

  def copy_resident_role_to_consumer_role(r_role)
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

  def get_members_as_people_for_enrollment(id)

  end
end