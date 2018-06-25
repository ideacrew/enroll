feins = ARGV[0].split(" ")

count = 0

Organization.where(:fein.in => feins).each do |organization|
  puts "Processing for #{organization.dba}"

  employer = organization.employer_profile
  bg_ids = employer.active_plan_year.benefit_groups.pluck(:id)

  Family.where(:"households.hbx_enrollments" => {:$elemMatch => {:benefit_group_id.in => bg_ids, :aasm_state.in => (HbxEnrollment::ENROLLED_STATUSES + HbxEnrollment::WAIVED_STATUSES - ["coverage_termination_pending"])}}).each do |family|

    enrollment = family.active_household.hbx_enrollments.where({
      :benefit_group_id.in => bg_ids, 
      :aasm_state.in => (HbxEnrollment::ENROLLED_STATUSES + HbxEnrollment::WAIVED_STATUSES - ["coverage_termination_pending"])
      }).sort_by(&:submitted_at).last

    ce = enrollment.benefit_group_assignment.try(:census_employee)
    next if ce.blank?
    next unless CensusEmployee::EMPLOYMENT_ACTIVE_STATES.include?(ce.aasm_state)
    if CensusEmployee::PENDING_STATES.include?(ce.aasm_state)
      next if ce.coverage_terminated_on.blank? || ce.coverage_terminated_on < employer.renewing_plan_year.start_on
    end

    if enrollment.present?
      renewal_bg_ids = employer.renewing_plan_year.benefit_groups.pluck(:id)

      passives = family.active_household.hbx_enrollments.where({
        :benefit_group_id.in => renewal_bg_ids, 
        :aasm_state.in => (HbxEnrollment::ENROLLED_STATUSES + HbxEnrollment::WAIVED_STATUSES + HbxEnrollment::RENEWAL_STATUSES)
        })

      if passives.empty?
        begin
          count += 1
          puts "Renewing #{ce.full_name}"
          factory = Factories::FamilyEnrollmentRenewalFactory.new
          factory.family = family
          factory.census_employee = ce
          factory.employer = employer
          factory.renewing_plan_year = employer.renewing_plan_year
          factory.renew
        rescue Exception => e
          puts "Renewal failed for #{ce.full_name} due to #{e.to_s}"
        end
      end
    end
  end
end

puts "Processed #{count} employees"