
require File.join(Rails.root, "lib/mongoid_migration_task")

class CorrectInvalidBenefitGroupAssignmentsForEmployer < MongoidMigrationTask
  def migrate
    action = ENV['action'].to_s
      case action
        when "corect_invalid_bga"
          corect_invalid_bga
        when "create_new_benefit_group_assignment"
          create_map_new_bga
      end
  end

  def organizations
    if ENV['fein'].present?
      Organization.where(fein: ENV['fein'])
    else
      Organization.exists(:employer_profile => true)
    end
  end

  def corect_invalid_bga
    organizations.each do |org|
      org.employer_profile.census_employees.each do |ce|
        ce.benefit_group_assignments.each do |bga|
          benefit_group = bga.benefit_group

          if benefit_group.blank?
            bga.delete
            puts "Deleting invalid benefit group assignments for #{ce.first_name} #{ce.last_name} for ER with legal name #{organizations.first.legal_name}" unless Rails.env.test?
            next
          end

          if bga.aasm_state == "coverage_selected" && bga.hbx_enrollment.blank?
            bga.update_attributes(aasm_state: "initialized")
            puts "Change invalid benefit group assignments for #{ce.first_name} #{ce.last_name} for ER with legal name #{organizations.first.legal_name} to initialized" unless Rails.env.test?
          end

          if !(benefit_group.start_on..benefit_group.end_on).cover?(bga.start_on)
            bga.update_attribute(:start_on, [bga.benefit_group.start_on, ce.hired_on].compact.max)
            puts "Updating the start date of benefit group assignment for #{ce.first_name} #{ce.last_name} for ER with legal name #{organizations.first.legal_name}" unless Rails.env.test?
          end

          next if bga.end_on.blank?

          if !(benefit_group.start_on..benefit_group.end_on).cover?(bga.end_on) || bga.end_on < bga.start_on
            bga.update_attribute(:end_on, bga.benefit_group.end_on)
            puts "Updating the end date of benefit group assignment for #{ce.first_name} #{ce.last_name} for ER with legal name #{organizations.first.legal_name}" unless Rails.env.test?
          end
        end
      end
    end
  end

  def create_map_new_bga
    census_employee = CensusEmployee.find(ENV['id'].to_s)
    enrollment = HbxEnrollment.by_hbx_id(ENV['enr_hbx_id'].to_s).first
    benefit_group = enrollment.benefit_group
    assignment = census_employee.benefit_group_assignments.where(benefit_group_id:benefit_group.id)
    assignment.present? ? (return "There is already bga present for the ce.") : census_employee.benefit_group_assignments.build(benefit_group_id: benefit_group.id, start_on: benefit_group.start_on)
    census_employee.save!
    puts "successfully built bga for the employee" unless Rails.env.test?
  end
end
