require File.join(Rails.root, "lib/mongoid_migration_task")

class DeleteDuplicateTaxHouseholds < MongoidMigrationTask
  def migrate
    begin
      hbx_id = ENV['person_hbx_id']
      person = Person.all.by_hbx_id(hbx_id).first
      count = 0
      if person.nil?
        puts "Unable to find any person record with the given hbx_id: #{hbx_id}" unless Rails.env.test?
        return
      end

      tax_households = []
      person.primary_family.active_household.tax_households.no_timeout.each do |household|
        count += 1
        puts "Processed #{count} tax_households" if count % 100 == 0

        is_duplicate = false
        person_records = household.tax_household_members.map{|a|a.person}
        if !tax_households.empty?
          tax_households.each do |th|
            if th.tax_household_members.count == household.tax_household_members.count
              people = th.tax_household_members.map{|a|a.person}
              if people == person_records
                is_duplicate = true
                break
              end
            end
          end

          is_duplicate ? household.destroy : tax_households << household
        else
          tax_households << household
        end
      end
      puts "Deleted all duplicate tax households"
    rescue StandardError => e
      puts e.message unless Rails.env.test?
    end
  end
end
