require File.join(Rails.root, "lib/mongoid_migration_task")

class UpdateConversionFlag < MongoidMigrationTask
  def migrate
    begin
      Organization.where(fein: ENV['fein']).first.employer_profile.update_attributes!(profile_source: ENV['profile_source'])
      puts "Conversion flag updated #{ENV['profile_source']}" unless Rails.env.test?
    rescue
      puts "Bad Employee Record" unless Rails.env.test?
    end
  end
end
