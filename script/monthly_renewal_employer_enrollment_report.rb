renewal_begin_date = Date.new(2018, 10, 1)
orgs = Organization.where(:"employer_profile.plan_years" => {:$elemMatch => {:start_on => renewal_begin_date, :aasm_state.in => PlanYear::RENEWING}})

CSV.open("#{Rails.root}/monthly_renewal_employer_enrollment_report_#{renewal_begin_date.strftime('%m_%d')}.csv", "w") do |csv|
  csv << [
    "Employer Legal Name",
    "Employer FEIN",
    "Renewal State",
    "#{renewal_begin_date.prev_year.year} Active Enrollments",
    "#{renewal_begin_date.prev_year.year} Passive Renewal Enrollments"
  ]

  orgs.each do |organization|

    puts "Processing #{organization.legal_name}"

    employer_profile = organization.employer_profile

    data = [
      employer_profile.legal_name,
      employer_profile.fein,
      employer_profile.renewing_plan_year.aasm_state.camelcase
    ]
    next if employer_profile.active_plan_year.blank?

    active_bg_ids = employer_profile.active_plan_year.benefit_groups.pluck(:id)
    families = Family.where(:"households.hbx_enrollments" => {:$elemMatch => {:benefit_group_id.in => active_bg_ids, :aasm_state.in => HbxEnrollment::ENROLLED_STATUSES}})

    if employer_profile.renewing_plan_year.present?
      if employer_profile.renewing_plan_year.renewing_enrolling? || employer_profile.renewing_plan_year.renewing_enrolled?
        renewal_bg_ids = employer_profile.renewing_plan_year.benefit_groups.pluck(:id)
      end
    end

    active_enrollment_count = 0
    renewal_enrollment_count = 0

    families.each do |family|

      enrollments = family.active_household.hbx_enrollments.where({
        :benefit_group_id.in => active_bg_ids,
        :aasm_state.in => HbxEnrollment::ENROLLED_STATUSES
      })

      %w(health dental).each do |coverage_kind|
        if enrollments.where(:coverage_kind => coverage_kind).present?
          active_enrollment_count += 1
        end
      end

      if renewal_bg_ids.present?
        renewal_enrollments = family.active_household.hbx_enrollments.where({
          :benefit_group_id.in => renewal_bg_ids,
          :aasm_state.in => HbxEnrollment::ENROLLED_STATUSES + ['auto_renewing']
        })

        %w(health dental).each do |coverage_kind|
          if renewal_enrollments.where(:coverage_kind => coverage_kind).present?
            renewal_enrollment_count += 1
          end
        end
      end
    end

    data += [active_enrollment_count, renewal_enrollment_count]
    csv << data
  end
end