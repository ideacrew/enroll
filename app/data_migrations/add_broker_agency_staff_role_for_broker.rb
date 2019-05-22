require File.join(Rails.root, 'lib/mongoid_migration_task')

class AddBrokerAgencyStaffRoleForBroker < MongoidMigrationTask

  def migrate
    people = Person.broker_role_certified.where("user" => {"$exists" => true}, "broker_agency_staff_roles" => {"$exists" => false})
    people.each do |person|
      begin
        broker_agency_profile = person.broker_role.broker_agency_profile
        if broker_agency_profile.present?
          person.broker_agency_staff_roles << ::BrokerAgencyStaffRole.new({
                                                 :broker_agency_profile => broker_agency_profile,
                                                 :aasm_state => 'active'
                                                                          })
          person.save!
          puts "Broker agency staff role added for broker with npn #{person.broker_role.npn}" unless Rails.env.test?
        else
          puts 'Broker agency profile not found' unless Rails.env.test?
        end
      rescue => e
        puts "unable to broker agency staff role for for broker with npn #{person.broker_role.npn}" + e.message unless Rails.env.test?
      end
    end
  end
end