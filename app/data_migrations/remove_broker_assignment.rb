require File.join(Rails.root, "lib/mongoid_migration_task")

class RemoveBrokerAssignment < MongoidMigrationTask
  def migrate
    begin
      person = Person.where(hbx_id: ENV['hbx_id']).first
      if person.primary_family.present?
        person.primary_family.current_broker_agency.update_attributes(is_active: false) if person.primary_family.current_broker_agency.present?
        puts "Removed broker for the primary family of a primary person with hbx_id: #{ENV['hbx_id']}" unless Rails.env.test?
      end
    rescue
      puts "Bad Person Record with given hbx_id: #{ENV['hbx_id']}" unless Rails.env.test?
    end
  end
end
