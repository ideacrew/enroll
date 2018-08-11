require File.join(Rails.root,"lib/mongoid_migration_task")

class DeactivateDuplicateFamily < MongoidMigrationTask

  def migrate
    person_hbx_id = ENV['hbx_id']
    person = Person.where(hbx_id: person_hbx_id).first

    if person.present?
      primary_family_id = person.primary_family.id
      all_families = Family.find_all_by_person(person)
      all_families.each do |family|
        if primary_family_id.to_s == family.id.to_s
        else
          family.is_active = false
          family.save(validate: false)
          puts "successfully deactivated a duplicate family for person #{person.full_name}" unless Rails.env.test
        end
      end
    else
      puts "no person found with hbx id: #{person_hbx_id}" unless Rails.env.test
    end
  end

end
