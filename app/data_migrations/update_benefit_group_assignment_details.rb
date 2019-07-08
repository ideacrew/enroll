require File.join(Rails.root, "lib/mongoid_migration_task")

class UpdateBenefitGroupAssignmentDetails < MongoidMigrationTask
  def migrate
    bga = bga_params
    action = ENV['action'].to_s
    case action
    when "change_aasm_state"
      change_aasm_sate(bga)
    when "unset_hbx_id"
      change_hbx_id(bga)
    end
  end

  def bga_params
    ce_id = ENV['ce_id'].to_s
    ce = CensusEmployee.where(id: ce_id).first
    if census_employee.nil?
      puts "No census employee was found with given ssn"
    else
      bga_id = ENV['bga_id'].to_s if ce.present?
      ce.benefit_group_assignments.where(id: bga_id).first
    end
  end

  def change_aasm_sate(bga)
    new_state = ENV['new_state'].to_s
    bga.expire_coverage!
    puts "Changed bga aasm state on date to #{new_state}" unless Rails.env.test?
  end

  def change_hbx_id(bga)
    bga.unset(:hbx_enrollment_id)
    if bga.save
      puts "done with unsetting enrollment id on bga " unless Rails.env.test?
    else
      puts "Oops! Something went wrong" unless Rails.env.test?
    end
  end
end
