require File.join(Rails.root, "lib/mongoid_migration_task")

class ActivateEmployeeRenewalBenefitGroupAssignments < MongoidMigrationTask

  def migrate
    feins = ENV['feins'].to_s.split(',')
    effective_on = Date.strptime(ENV['effective_on'].to_s, "%m/%d/%Y") if ENV['effective_on'].present?

    if feins.empty?
      raise "Wrong Arguments: Please provide FEIN for the employer"
    end

    if effective_on.blank?
      raise "Wrong Arguments: Please provide effective_on for the renewal plan year"
    end

    feins.each do |fein|
      employer_profile  = EmployerProfile.find_by_fein(fein)
      plan_year         = employer_profile.plan_years.where(:start_on => effective_on, :aasm_state => :active).first
      benefit_group_ids = plan_year.benefit_groups.pluck(:id)
      census_employees  = employer_profile.census_employees.non_terminated.where(
                            :"benefit_group_assignments" => {
                              :$elemMatch => {
                                :benefit_group_id.nin => benefit_group_ids, 
                                :is_active => true
                              }
                            })

      puts "Found #{census_employees.count} employee under #{employer_profile.legal_name} with incorrect active assignment." unless Rails.env.test?

      census_employees.no_timeout.each do |census_employee|
        assignment = census_employee.benefit_group_assignments.where({
          :benefit_group_id.in => benefit_group_ids
          }).first
        assignment.make_active
        puts "activated assignment for #{census_employee.full_name}" unless Rails.env.test?
      end
    end
  end
end
