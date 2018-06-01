require File.join(Rails.root, "lib/mongoid_migration_task")

class RemovePlanOfferings< MongoidMigrationTask
  def migrate
    organizations = Organization.where(fein: ENV['fein'])
    aasm_state = ENV['aasm_state']
    given_carrier_profile_id = ENV['carrier_profile_id'].to_s
    if organizations.size!= 1
      raise "issues with given fein"
    end
    organizations.first.employer_profile.plan_years.where(aasm_state: aasm_state).first.benefit_groups.first.elected_plans.select{|p| p.carrier_profile_id.to_s == given_carrier_profile_id}.each(&:destroy)
    puts "removed the carrier from employer level offerings" unless Rails.env.test?
  end
end



