
require File.join(Rails.root, "lib/mongoid_migration_task")

class RemoveBenefitPackage < MongoidMigrationTask
  def migrate
    organizations = Organization.where(fein: ENV['fein'])
    state = ENV['aasm_state'].to_s
    id = ENV['id']
    if organizations.size !=1
      raise 'Issues with fein'
    end
    organizations.first.employer_profile.plan_years.where(aasm_state: state).first.benefit_groups.where(_id: id).first.benefit_group_assignments.to_a.each do |bga|
      if bga.hbx_enrollments.present?
        bga.hbx_enrollments.to_a.each do |enrollment|
          enrollment.delete
          puts "Removing enrollment" unless Rails.env.test?
        end
      end
      bga.delete
      puts "Removing benefit group assignment" unless Rails.env.test?
    end
    organizations.first.employer_profile.plan_years.where(aasm_state: state).first.benefit_groups.where(_id: id).first.delete
  end
end
