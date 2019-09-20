require File.join(Rails.root, "lib/mongoid_migration_task")

class UpdateBenefitGroupAssignmentDetails < MongoidMigrationTask
  def migrate
    bga = bga_params
    action = ENV['action'].to_s
    case action
    when "change_aasm_state"
      change_aasm_sate(bga)
    end
  end

  def bga_params
    ce_id = ENV['ce_id'].to_s
    ce = CensusEmployee.where(id: ce_id).first
    bga_id = ENV['bga_id'].to_s if ce.present?
    ce.benefit_group_assignments.where(id: bga_id).first
  end

  def change_aasm_sate(bga)
    new_state = ENV['new_state'].to_s
    bga.update_attributes!(aasm_state: new_state)
    puts "Changed bga aasm state on date to #{new_state}" unless Rails.env.test?
  end
end
