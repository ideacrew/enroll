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

      person_hbx_ids = []
      person.primary_family.active_household.tax_households.each do |household|
        household.tax_household.members.each do |member|
          hbx_id = member.person.id
          if !person_hbx_ids.empty?
            if person_hbx_ids.include?(hbx_id)
              member.destroy
            else
              person_hbx_ids << hbx_id
            end
          else
            person_hbx_ids << hbx_id
          end
        end
      end

    rescue StandardError => e
      puts e.message unless Rails.env.test?
    end
  end
end
