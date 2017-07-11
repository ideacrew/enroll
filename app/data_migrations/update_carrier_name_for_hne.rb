require File.join(Rails.root, "lib/mongoid_migration_task")

class UpdateCarrierNameForHne < MongoidMigrationTask
  def migrate
    org = Organization.where(fein: "042864973").last
    org.legal_name = "Health New England"
    org.save
  end
end
