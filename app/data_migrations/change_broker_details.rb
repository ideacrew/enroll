require File.join(Rails.root, "lib/mongoid_migration_task")

class ChangeBrokerDetails < MongoidMigrationTask
  def migrate
    broker_role = BrokerRole.by_npn(ENV['npn']).first
    if broker_role.nil?
      puts "No broker role was found with given hbx_id" unless Rails.env.test?
    else
      broker_role.update_attributes(market_kind:ENV['new_market_kind'])
      puts "update the market kind of broker to: #{ENV['new_market_kind']}" unless Rails.env.test?
    end
  end
end
