require File.join(Rails.root, "lib/migration_task")

class PrimaryPOC < MigrationTask 
  def create_employer
    o1 = Organization.create(hbx_id:1928373, legal_name:"Test Employer", dba:"Test Employer", fein:"102812h12", is_active:true)
  end
end