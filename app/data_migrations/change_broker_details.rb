require File.join(Rails.root, "lib/mongoid_migration_task")

class ChangeBrokerDetails < MongoidMigrationTask
  def migrate
    begin
      person = Person.where(hbx_id: ENV['hbx_id'])
      if person.size != 1
        raise "Invalid Hbx Id"
      end
        person.first.broker_role.update_attributes(market_kind:ENV['new_market_kind'])
        puts "Updating market kind for Person with hbx id: #{ENV['hbx_id']} " unless Rails.env.test?
        person.first.broker_role.broker_agency_profile.update_attributes(market_kind:ENV['new_market_kind'])
        puts "update the market kind under broker agency profile to: #{ENV['new_market_kind']}" unless Rails.env.test?
    rescue
      puts "Bad Person Record" unless Rails.env.test?
    end
  end
end