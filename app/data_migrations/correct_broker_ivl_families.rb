require File.join(Rails.root, "lib/mongoid_migration_task")

class CorrectBrokerIvlFamilies < MongoidMigrationTask
  def migrate
    writing_agent_id = ENV['writing_agent_id']
    broker_agency_profile_id = ENV['broker_agency_profile_id']
    Family.where(:broker_agency_accounts.exists=>true,:'broker_agency_accounts'=> {:$elemMatch => {:writing_agent_id=>BSON::ObjectId(writing_agent_id)}}).each do |fam|
      fam.broker_agency_accounts.unscoped.each do |agency_account|
        if agency_account.writing_agent_id == BSON::ObjectId(writing_agent_id)
         agency_account.update_attributes!(broker_agency_profile_id: broker_agency_profile_id)
        end
      end
    end
  end
end