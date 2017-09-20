require File.join(Rails.root, "lib/mongoid_migration_task")

class RemoveDertifiedPendingBrokersFromFamilies < MongoidMigrationTask
  def migrate
    families = Family.where("broker_agency_accounts" => {"$exists" => true})
  
    families.each do |family|
      broker = family.current_broker_agency.try(:writing_agent)
      if broker.present? && broker.aasm_state.present?
        if broker.aasm_state == "decertified" || broker.aasm_state == "broker_agency_pending"
          family.terminate_broker_agency
        end
      end
    end
  end
end