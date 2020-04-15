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

      when "change_ssn"
        change_ssn
      when "delink_employee_role"
        delink_employee_role
      when "link_or_construct_employee_role"
        link_or_construct_employee_role
    end
  end

  private

  def census_employee_by_ssn
    encrypted_ssn = ENV["encrypted_ssn"]
    decrypted_ssn = SymmetricEncryption.decrypt(encrypted_ssn)

    census_employees = CensusEmployee.by_ssn(decrypted_ssn)
    if census_employees.size != 1
      if census_employees.present? && ENV['employer_fein'].present?
        census_employee(decrypted_ssn, ENV['employer_fein'])
      end
      puts "Found 0 or more than 1 Census Records with this SSN" unless Rails.env.test?
      return 
    else
      census_employees.first
    end
  end

  def change_ssn
    new_encrypted_ssn = ENV["new_encrypted_ssn"]
    new_decrypted_ssn = SymmetricEncryption.decrypt(new_encrypted_ssn)

    census_employee = census_employee_by_ssn

    if !CensusEmployee::ELIGIBLE_STATES.include?(census_employee.aasm_state)
      puts "An employee's identifying information may change only when in 'eligible' status. You have to delink the Employee Role" unless Rails.env.test?
      return
    else
      census_employee.update_attributes!(ssn: new_decrypted_ssn)
      puts "updated ssn on Census Record" unless Rails.env.test?
    end
  end

  def delink_employee_role
    census_employee = census_employee_by_ssn

    if census_employee.may_delink_employee_role?
      census_employee.delink_employee_role!
      puts "De-linked employee role" unless Rails.env.test?
    else
      puts "You cannot delink employee role" unless Rails.env.test?
    end
  end

  def link_or_construct_employee_role
    person = Person.by_hbx_id(ENV['hbx_id'].to_s).first
    return if person.blank?

    ssn = person.ssn
    census_employee = census_employee(ssn, ENV['employer_fein'])
    return unless census_employee.active_benefit_group_assignment.present?

    if census_employee.employee_role.present? && census_employee.may_link_employee_role?
      fix_benefit_group_assignment(census_employee) unless census_employee.valid?
      census_employee.link_employee_role!
      puts 'Census Employee successfully linked' unless Rails.env.test?
    elsif census_employee.has_benefit_group_assignment?
      Factories::EnrollmentFactory.build_employee_role(person, nil, census_employee.employer_profile, census_employee, census_employee.hired_on)
      puts 'Build Employee Role' unless Rails.env.test?
    end
  end

  def fix_benefit_group_assignment(census_employee)
    census_employee.benefit_group_assignments.each do |benefit_group_assignment|
      next if benefit_group_assignment.valid?

      hbx_enrollment = benefit_group_assignment.hbx_enrollment
      hbx_enrollment.sponsored_benefit_package_id = benefit_group_assignment.benefit_package_id
      hbx_enrollment.save
    end
  end

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
    organization = BenefitSponsors::Organizations::Organization.employer_by_fein(employer_fein).first
    employer_profile_id = organization.employer_profile.id if organization
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
