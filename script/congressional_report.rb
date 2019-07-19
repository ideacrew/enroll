# frozen_string_literal: true

#RAILS_ENV=production bundle exec rails runner -e production script/congressional_report.rb "fein1" "fein2" "fein 3"
renewal_begin_date = Date.new(2018, 1, 1)
feins = ARGV

BenefitSponsors::Organizations::Organization.where(:fein.in => feins).each do |organization|

  CSV.open("#{Rails.root}/congressional_enrollments_#{organization.fein}.csv", "w") do |csv|

    puts "Processing #{organization.dba}"

    csv << [
      "First name",
      "Last Name",
      "Roster status",
      "Employment Terminated On",
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
      "#{renewal_begin_date.year} status",
      "#{renewal_begin_date.year} total employee cost",
      "#{renewal_begin_date.year} total employer contribution",
      "#{renewal_begin_date.year} total premium"
    ]

    employer_profile = organization.employer_profile
    renewal_bg_ids = employer_profile.renewal_benefit_application.benefit_packages.pluck(:id) if employer_profile.renewal_benefit_application.present?
    active_bg_ids = employer_profile.active_benefit_application.benefit_packages.pluck(:id)
    count = 0

    employer_profile.census_employees.each do |ce|
      if CensusEmployee::EMPLOYMENT_ACTIVE_STATES.include?(ce.aasm_state) || (CensusEmployee::EMPLOYMENT_TERMINATED_STATES.include?(ce.aasm_state) && ce.coverage_terminated_on.present? && ce.coverage_terminated_on > Date.new(2017,1,1))

        if ce.employee_role.present?
          person = ce.employee_role.person
          family = person.primary_family      
        else
          assignment_ids = ce.benefit_group_assignments.pluck(:id)
          family = Family.where(:"household.hbx_enrollments.benefit_group_assignment_id".in => assignment_ids).first
          person = family.primary_applicant.person if family.present?
        end

        count += 1

        if count % 100 == 0
          puts "Processed #{count} employees"
        end

        active_enrollment = family.active_household.hbx_enrollments.where({
          :sponsored_benefit_package_id.in => active_bg_ids,
          :aasm_state.in => HbxEnrollment::ENROLLED_STATUSES + ['coverage_terminated', 'inactive', 'auto_renewing', 'renewing_waived']
          }).max_by(&:submitted_at) if family.present?

        renewal_enrollment = family.active_household.hbx_enrollments.where({
          :sponsored_benefit_package_id.in => renewal_bg_ids,
          :aasm_state.in => ['auto_renewing', 'renewing_waived']
          }).max_by(&:submitted_at) if family.present? && employer_profile.renewal_benefit_application.present?

        data = [ce.first_name, ce.last_name, ce.aasm_state.humanize]
        if CensusEmployee::EMPLOYMENT_TERMINATED_STATES.include?(ce.aasm_state)
          data += (ce.employment_terminated_on.present? ? [ce.employment_terminated_on.strftime("%m/%d/%Y")] : [""])
        else
          data += [""]
        end
        data += (person.present? ? [person.hbx_id] : [""])
    
        if active_enrollment.present?
          data += [
            active_enrollment.hbx_id,
            active_enrollment.product.try(:hios_id),
            active_enrollment.effective_on.strftime("%m/%d/%Y"),
            active_enrollment.coverage_kind,
            active_enrollment.aasm_state.humanize
          ]
        else
          data += 5.times.collect{ "" }
        end

        if renewal_enrollment.present?
          data += [
            renewal_enrollment.hbx_id,
            renewal_enrollment.product.try(:hios_id),
            renewal_enrollment.effective_on.strftime("%m/%d/%Y"),
            renewal_enrollment.coverage_kind,
            renewal_enrollment.aasm_state.humanize,
            renewal_enrollment.total_employee_cost,
            renewal_enrollment.total_employer_contribution,
            renewal_enrollment.total_premium
          ]
        end

        csv << data
      end
    end
  end
end