feins = ARGV[0].split(" ")

CensusEmployee.where(:aasm_state.in => %w(newly_designated_linked newly_designated_eligible)).each do |census_employee|
   if feins.include?(census_employee.employer_profile.fein)
      census_employee.rebase_new_designee!
      puts "Rebased #{census_employee.full_name} to #{census_employee.aasm_state}" 
   end
end

%w(2685748 2288952 19750474 180970).each do |hbx_id|
  person = Person.by_hbx_id(hbx_id).first
  role = person.active_employee_roles.detect{|role| role.employer_profile.fein == '536002523'}
  person.primary_family.active_household.hbx_enrollments.where(:effective_on => Date.new(2017,1,1), :aasm_state => 'auto_renewing').each do |enrollment|
    enrollment.update(:employee_role_id => role.id) if enrollment.employee_role.employer_profile.fein == '536002523'
  end
end

Organization.where(:fein.in => feins).each do |organization|
  puts "Processing for #{organization.dba}"

  employer = organization.employer_profile
  bg_ids = employer.active_plan_year.benefit_groups.pluck(:id)

  Family.where(:"households.hbx_enrollments" => {:$elemMatch => {:benefit_group_id.in => bg_ids, :aasm_state.in => (HbxEnrollment::RENEWAL_STATUSES + ['renewing_waived'])}}).each do |family|

    enrollments = family.active_household.hbx_enrollments.where({
      :benefit_group_id.in => bg_ids, 
      :aasm_state.in => (HbxEnrollment::RENEWAL_STATUSES + HbxEnrollment::ENROLLED_STATUSES + HbxEnrollment::WAIVED_STATUSES)
      }).sort_by(&:submitted_at)

    begin
      enrollments.each do |enrollment|
        census_employee = enrollment.benefit_group_assignment.census_employee

        if enrollment.benefit_group_assignment.blank?
          raise "benefit package missing enrollment: #{family.primary_applicant.person.full_name} (#{family.primary_applicant.person.hbx_id})"
        end

        if enrollment.employee_role.present? && enrollment.employee_role.census_employee != census_employee
          raise "Bad enrollment: #{family.primary_applicant.person.full_name} (#{family.primary_applicant.person.hbx_id})"
        end
      end
    rescue Exception => e
      puts "Exception: #{e.to_s}"
      next
    end

    if enrollments.size > 1
      enrollment_for_renewal = enrollments.pop

      enrollments.each do |enrollment|
        if enrollment.renewing_waived? || enrollment_for_renewal.renewing_waived? || enrollment_for_renewal.inactive?
          enrollment.cancel_coverage! if enrollment.may_cancel_coverage?
        else
          if enrollment.effective_on >= enrollment_for_renewal.effective_on
            enrollment.cancel_coverage! if enrollment.may_cancel_coverage?            
          end
        end
      end

      enrollment_for_renewal.begin_coverage! if enrollment_for_renewal.may_begin_coverage?
    else
      enrollment = enrollments.first
      census_employee = enrollment.benefit_group_assignment.census_employee

      if (CensusEmployee::EMPLOYMENT_TERMINATED_STATES + CensusEmployee::PENDING_STATES).include?(census_employee.aasm_state)
        if enrollment.renewing_waived?
          enrollment.cancel_coverage! if enrollment.may_cancel_coverage?
        end
      else
        enrollment.begin_coverage! if enrollment.may_begin_coverage?
      end
    end

  end
end

puts "Generating Rnewing Plan years..."
plan_year_renewal_factory = Factories::PlanYearRenewalFactory.new
Organization.where(:fein.in => feins).each do |organization|
  puts "Processing for #{organization.dba}"
  plan_year_renewal_factory.employer_profile = organization.employer_profile
  plan_year_renewal_factory.is_congress = true
  plan_year_renewal_factory.renew
end

puts "Updating Open enrollment dates..."
Organization.where(:fein.in => feins).each do |organization|
  puts "Processing for #{organization.dba}"
  employer  = organization.employer_profile
  plan_year = employer.renewing_plan_year
  plan_year.open_enrollment_start_on = Date.new(2017,11,13)
  plan_year.open_enrollment_end_on = Date.new(2017,12,11)
  plan_year.save(:validate => false)
end

puts "Fixing Benefit group titles..."
Organization.where(:fein.in => feins).each do |organization|
  puts "Processing for #{organization.dba}"
  bg  = organization.employer_profile.renewing_plan_year.benefit_groups.first
  bg.update(title: bg.title.gsub(/2017/, "2018").gsub(/\(2018\)/, '').strip)
end

puts "Publishing Plan Years..."
Organization.where(:fein.in => feins).each do |organization|
  puts "Processing for #{organization.dba}"
  employer  = organization.employer_profile
  employer.renewing_plan_year.publish!
end
