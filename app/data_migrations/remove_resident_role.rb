require File.join(Rails.root, "lib/mongoid_migration_task")

class RemoveResidentRole < MongoidMigrationTask

  # this script will remove the resident role from any person who does not have
  # any enrollments designated as coverall but has an erroneous resident role
  def migrate
    people = Person.where("resident_role" => {"$exists" => true, "$ne" => nil})
    people.each do |person|
      # initialize flag to be true at the beginning of each iteration
      remove_resident_role = true
      person.primary_family && person.primary_family.households.first.hbx_enrollments.each do |enrollment|
        # set flag to false
        if enrollment.kind == "coverall"
          remove_resident_role = false
        end
      end
      # remove resident role if none of the enrollments are designated as coverall
      if remove_resident_role == true
        person.resident_role.destroy
        puts "removed resident role for Person: #{person.hbx_id} unless Rails.env.test?"
      end
    end
  end
end