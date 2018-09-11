renewal_begin_date = Date.new(2018, 10, 1)
orgs = Organization.where(:"employer_profile.plan_years" => {:$elemMatch => {:start_on => renewal_begin_date, :aasm_state.in => PlanYear::RENEWING}}).limit(50)

def enrollment_details_by_coverage_kind(enrollments, coverage_kind)
  enrollment = enrollments.where(:coverage_kind => coverage_kind).sort_by(&:submitted_at).last
  return [] if enrollment.blank?
  [
    enrollment.hbx_id,
    enrollment.plan.hios_id,
    enrollment.effective_on.strftime("%m/%d/%Y"),
    enrollment.coverage_kind,
    enrollment.aasm_state.humanize
  ]
end

CSV.open("#{Rails.root}/monthly_renewal_employer_enrollment_detail_report_#{renewal_begin_date.strftime('%m_%d')}.csv", "w") do |csv|
  csv << [
    "Employer Legal Name",
    "Employer FEIN",
    "Renewal State",
    "First name",
    "Last Name",
    "Roster status",
    "Hbx ID",
    "#{renewal_begin_date.prev_year.year} enrollment", 
    "#{renewal_begin_date.prev_year.year} plan", 
    "#{renewal_begin_date.prev_year.year} effective_date",
    "#{renewal_begin_date.prev_year.year} enrollment kind",
    "#{renewal_begin_date.prev_year.year} status",
    "#{renewal_begin_date.year} enrollment", 
    "#{renewal_begin_date.year} plan", 
    "#{renewal_begin_date.year} effective_date",
    "#{renewal_begin_date.year} enrollment kind",
    "#{renewal_begin_date.year} status"
  ]

  orgs.each do |organization|

    puts "Processing #{organization.legal_name}"

    employer_profile = organization.employer_profile
    next if employer_profile.active_plan_year.blank?
    active_bg_ids = employer_profile.active_plan_year.benefit_groups.pluck(:id)
    families = Family.where(:"households.hbx_enrollments" => {:$elemMatch => {:benefit_group_id.in => active_bg_ids, :aasm_state.in => HbxEnrollment::ENROLLED_STATUSES}})

    if employer_profile.renewing_plan_year.present?
      if employer_profile.renewing_plan_year.renewing_enrolling? || employer_profile.renewing_plan_year.renewing_enrolled?
        renewal_bg_ids = employer_profile.renewing_plan_year.benefit_groups.pluck(:id)
      end
    end

    families.each do |family|
    
      enrollments = family.active_household.hbx_enrollments.where({
        :benefit_group_id.in => active_bg_ids,
        :aasm_state.in => HbxEnrollment::ENROLLED_STATUSES
      })

      employee_role = enrollments.last.employee_role 
      if employee_role.present?
        employee = employee_role.census_employee
      else
        role = family.primary_applicant.person.employee_roles.detect{|role| role.employer_profile_id.to_s == employer_profile.id.to_s}

        if role.present?
          employee = role.census_employee
        end
      end

      if renewal_bg_ids.present?
        renewal_enrollments = family.active_household.hbx_enrollments.where({
          :benefit_group_id.in => renewal_bg_ids,
          :aasm_state.in => HbxEnrollment::ENROLLED_STATUSES + ['auto_renewing']
          })
      end

      employer_employee_data = [
        employer_profile.legal_name,
        employer_profile.fein,
        employer_profile.renewing_plan_year.aasm_state.camelcase
      ]

      if employee.present?
        employer_employee_data += [employee.first_name, employee.last_name, employee.aasm_state.humanize, employee_role.person.hbx_id]
      else
        employer_employee_data += [nil, nil, nil, nil]
      end


      %w(health dental).each do |coverage_kind|
        next if enrollments.where(:coverage_kind => coverage_kind).blank?

        data = employer_employee_data
        data += enrollment_details_by_coverage_kind(enrollments, coverage_kind)
        if renewal_bg_ids.present?
          data += enrollment_details_by_coverage_kind(renewal_enrollments, coverage_kind)
        end

        csv << data
      end
    end
  end
end