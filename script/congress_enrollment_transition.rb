CSV.open("#{Rails.root}/congressional_data_cleanup.csv", "w") do |csv|

  csv << [
    "Employer Name",
    "Employer FEIN",
    "First name",
    "Last Name",
    "Person Hbx ID",
    "Roster status",
    "Employment Terminated On",
    "2017 enrollment hbx_id", 
    "2017 plan", 
    "2017 effective_date",
    "2017 status",
    "Submitted At"
  ]

  Organization.where(:fein.in => ["536002523", "536002522", "536002558"]).each do |organization|
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

      # enrollments.each do |enrollment|
      #   census_employee = enrollment.benefit_group_assignment.census_employee
      #   person = family.primary_applicant.person

      #   csv << [
      #     employer.dba,
      #     employer.fein,
      #     person.first_name,
      #     person.last_name,
      #     person.hbx_id,
      #     census_employee.aasm_state.humanize,
      #     census_employee.employment_terminated? ? census_employee.employment_terminated_on.strftime("%m/%d/%Y") : "",
      #     enrollment.hbx_id,
      #     enrollment.plan.present? ? enrollment.plan.hios_id : "",
      #     enrollment.effective_on.strftime("%m/%d/%Y"),
      #     enrollment.aasm_state.humanize,
      #     (enrollment.submitted_at || enrollment.created_at).strftime("%m/%d/%Y")
      #   ]
      # end
      
    end
  end
end