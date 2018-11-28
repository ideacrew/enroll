require File.join(Rails.root, "lib/mongoid_migration_task")

class UpdateWritingAgentId < MongoidMigrationTask
  def migration
    valid_writing_agent_id = ENV['valid_writing_agent_id']

    person = Person.where(hbx_id: ENV['hbx_id']).first
    puts "Invalid hbx_id" if person.count =! 1
    en = person.primary_family.broker_agency_accounts if person.primary_family.present?
    en.detect { |account| account.is_active? }
    en.update_attributes!(writing_agent_id: valid_writing_agent_id)
    puts "updated writing_agent_id for broker_agency_accounts" unless Rails.env.test?
  end
end




