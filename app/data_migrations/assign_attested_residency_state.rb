require File.join(Rails.root, "lib/mongoid_migration_task")

class AssignAttestedResidency < MongoidMigrationTask
  def families
    Family.by_enrollment_individual_market.all_enrollments
  end

  def assign_attested(family_member)
    family_member.person.consumer_role.update_attributes(:local_residency_validation => "attested")
  end

  def migrate
    families.each do |family|
      family.family_members.each do |family_member|
        begin
          assign_attested(family_member) if family_member.person.consumer_role && family_member.person.consumer_role.local_residency_validation != "outstanding"
        rescue
          $stderr.puts "Issue migrating family: #{family}, person: hbx_id: #{family_member.person.hbx_id}, id: #{family_member.person.id}" unless Rails.env.test?
        end
      end
    end
  end
end
