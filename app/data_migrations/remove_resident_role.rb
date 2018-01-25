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
      people = []
      people << Person.where(id: ENV['p_to_fix_id'].to_s).first
    end
    people.each do |person|
      # exclude the valid coverall enrollments
      unless correct_assignments.include?(person.id.to_s)
        begin
          person.primary_family && person.primary_family.active_household.hbx_enrollments.each do |enrollment|
            # first fix any enrollments - can only be inividual or coverall kinds
            if enrollment.kind == "coverall" || enrollment.kind == "individual"
              enrollment.kind = "individual"
              # check for all members on enrollment to remove all resident roles
              if enrollment.hbx_enrollment_members.size > 1
                enrollment.hbx_enrollment_members.each do |member|
                  if member.person.consumer_role.present?
                    member.person.resident_role.destroy if member.person.resident_role.present?
                  elsif member.person.resident_role.present?
                      copy_resident_role_to_consumer_role(member.person.resident_role)
                      member.person.resident_role.destroy
                  end
                end
                enrollment.reload
                #at this point everyone should have a consumer role
              elsif person.consumer_role.nil?
                copy_resident_role_to_consumer_role(person.resident_role)
              end
              # need to explicitly reload person object
              person_reload = Person.find(person.id)
              enrollment.consumer_role_id = person_reload.consumer_role.id
              enrollment.resident_role_id = nil
              enrollment.save!
            end
            # avoid unnecessary destroy calls and remove resident role for person with shop enrollments only
            person_reload ||= Person.find(person.id)
            person_reload.resident_role.destroy if person_reload.resident_role.present?
            puts "removed resident role for Person: #{person.hbx_id}" unless Rails.env.test?
          end
        rescue Exception => e
          puts e.backtrace
        end
        # in case there are no enrollments for the person
        person_reload ||= Person.find(person.id)
        copy_resident_role_to_consumer_role(person_reload.resident_role) if person_reload.consumer_role.nil?
        person_reload.resident_role.destroy if person_reload.resident_role.present?
        puts "removed resident role for Person: #{person.hbx_id}" unless Rails.env.test?
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

end