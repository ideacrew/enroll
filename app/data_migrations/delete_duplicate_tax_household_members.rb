require File.join(Rails.root, "lib/mongoid_migration_task")

class DeleteDuplicateTaxHouseholdMembers < MongoidMigrationTask
  def migrate
    begin
      hbx_id = ENV['person_hbx_id']
      person = Person.all.by_hbx_id(hbx_id).first

      if person.nil?
        puts "Unable to find any person record with the given hbx_id: #{hbx_id}" unless Rails.env.test?
        return
      end

      member_ids = []
      person.primary_family.active_household.tax_households.each do |household|
        p "Checking tax household id " + household.id
        p "Checking #{household.tax_household_members.count} members"
        person_hbx_ids = []
        member_count = 0
        deletion_count = 0
        household.tax_household_members.each do |member|
          member_count += 1
          hbx_id = member.person.hbx_id
          if person_hbx_ids.include?(hbx_id)
            member.destroy
            deletion_count += 1
          else
            person_hbx_ids << hbx_id
          end
        end
        p "Checked #{member_count} tax_household_members, deleted #{deletion_count}"
      end

    rescue StandardError => e
      puts e.message unless Rails.env.test?
    end
  end
end
