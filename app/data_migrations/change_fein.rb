require File.join(Rails.root, "lib/mongoid_migration_task")

class ChangeFein< MongoidMigrationTask
  def migrate
    trigger_single_table_inheritance_auto_load_of_child = VlpDocument

    fein1 = ENV['old_fein']
    fein2 = ENV['new_fein']

    org1 = Organization.where(fein: fein1).first
    org2 = Organization.where(fein: fein2).first

    if org1.nil?
      puts "No organization was found by the given fein: #{fein1}" unless Rails.env.test?
    else
      org1.unset(:fein)
      org2.unset(:fein) if org2.present?
      org1.update_attributes(fein: fein2)
      puts "Changed fein to #{fein2}" unless Rails.env.test?
    end
  end
end
