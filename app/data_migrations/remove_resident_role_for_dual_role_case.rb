require File.join(Rails.root, "lib/mongoid_migration_task")

class RemoveResidentRoleForDualRoleCase < MongoidMigrationTask
  def reset_resident_role(person)
    person.individual_market_transitions.resident_types.each do |imt|
      imt.destroy!
    end
    person.resident_role.destroy!
    person.reload
    person.save!
  end

  def migrate
    people = Person.by_hbx_id(ENV['hbx_id'])
    raise "No person found or more than one person found for hbx_id: #{ENV['hbx_id']}" if people.count != 1
    person = people.first
    raise "Given person is not primary person for any family" unless person.primary_family.present?
    raise "This person's family has enrollments, please refactor the rake to handle family with enrollments" if person.primary_family.enrollments.present?
    raise "This person's family has more than 1 family member, please refactor the rake to handle family with more members" if person.primary_family.family_members.count != 1
    raise "Cannot remove resident role as this person doesn't have any other active role" unless (person.has_active_resident_role? && (person.has_active_consumer_role? || person.has_active_employee_role?))
    begin
      reset_resident_role(person)
      puts "Successfully removed resident role and the IMTs" unless Rails.env.test?
    rescue => e
      e.message
    end
  end
end
