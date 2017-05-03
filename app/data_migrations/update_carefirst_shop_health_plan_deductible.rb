require File.join(Rails.root, "lib/mongoid_migration_task")

class UpdateCarefirstShopHealthPlanDeductible < MongoidMigrationTask
  def migrate
    plan = Plan.where(active_year: 2017, name: "BluePreferred PPO HSA/HRA Silver 2000").last
    puts "Updating plan deductible and family deductible: #{plan.name}"
    plan.deductible = "$2,000"
    plan.family_deductible = "$2000 per person | $4000 per group"
    plan.save
    puts "Successfully updated plan deductible and family deductible for: #{plan.name}"
  end
end
