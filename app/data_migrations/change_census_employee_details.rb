require File.join(Rails.root, "lib/mongoid_migration_task")

class ChangeCensusEmployeeDetails < MongoidMigrationTask
  def migrate
    action = ENV['action'].to_s

    case action
      when "update_employment_terminated_on"
        ssns = ENV['ssns'].split(",")
        terminated_on = Date.strptime(ENV['terminated_on'], "%Y%m%d")
        employer_fein = ENV['employer_fein']
        update_employment_terminated_on(employer_fein, ssns, terminated_on)
    end

  end

  private
  def update_employment_terminated_on(employer_fein, ssns, terminated_on)
    ssns.each do |ssn|
      begin
        census_employee = census_employee(ssn, employer_fein)
        if census_employee.employment_terminated_on.present?
          update_terminated_on(census_employee,  terminated_on)
          update_enrollments(census_employee, terminated_on)
        end
      rescue Exception => e
        puts e.message unless Rails.env.test?
      end
    end
  end

  def census_employee(ssn, employer_fein)
    employer_profile_id = Organization.where(fein: employer_fein).first.employer_profile.id
    census_employees = CensusEmployee.by_ssn(ssn).by_employer_profile_id(employer_profile_id)

    if census_employees.count == 0
      raise("Census_employee not found SSN #{ssn} Employer FEIN #{employer_fein}")
    else
      census_employees.first
    end
  end

  def update_terminated_on(census_employee, terminated_on)
    census_employee.employment_terminated_on = terminated_on
    census_employee.save!
  end


  def update_enrollments(census_employee, terminated_on)
    census_employee.update_attributes!({:coverage_terminated_on => terminated_on})

    [census_employee.active_benefit_group_assignment, census_employee.renewal_benefit_group_assignment].compact.each do |assignment|
      enrollments = assignment.hbx_enrollments
      enrollments.each do |enrollment|
        if enrollment.coverage_terminated?
          enrollment.terminated_on = terminated_on
          enrollment.save!
        end
      end
    end
  end
end
