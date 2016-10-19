
require File.join(Rails.root, "lib/mongoid_migration_task")

class ChangeEmployerContributions < MongoidMigrationTask
  def migrate
    organizations = Organization.where(fein: ENV['fein'])
    state = ENV['aasm_state'].to_s
    relationship = ENV['relationship'].to_s
    premium = ENV['premium']
    if organizations.size !=1
      raise 'Issues with fein'
    end
    organizations.first.employer_profile.plan_years.where(aasm_state: state).first.benefit_groups.first.relationship_benefits.where(:relationship => relationship).first.update_attributes(:premium_pct => premium)
  end
end
