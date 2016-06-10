namespace :migrations do
  desc "create missing consumer roles for dependents"
  task :mid_year_employer_terminations => :environment do

    employers = {
      "201904217" => "5/31/2016",
      "464567869" => "5/31/2016",
      "521224516" => "5/31/2016",
      "760830661" => "5/31/2016"
    }

    employers.each do |fein, termination_date|
      organizations = Organization.where(fein: fein)

      if organizations.size > 1
        puts "found more than 1 for #{legal_name}"
      end

      puts "Processing #{organizations.first.legal_name}"
      termination_date = Date.strptime(termination_date, "%m/%d/%Y")

      organizations.each do |organization|

        organization.employer_profile.plan_years.published.where(:"end_on".lte => TimeKeeper.date_of_record).each do |plan_year|
          enrollments = enrollments_for_plan_year(plan_year)

          enrollments.each do |hbx_enrollment|
            hbx_enrollment.expire_coverage! if hbx_enrollment.may_expire_coverage?
            benefit_group_assignment = hbx_enrollment.benefit_group_assignment
            benefit_group_assignment.expire_coverage! if benefit_group_assignment.may_expire_coverage?
          end

          plan_year.expire! if plan_year.may_expire?
        end

        plan_year = organization.employer_profile.plan_years.published_or_renewing_published.where({:"start_on".lte => termination_date, :"end_on".gte => termination_date}).first
        
        if plan_year.blank?
          puts "Active plan year for #{termination_date.strftime('%y/%m/%d')} not found"
          next
        end

        if plan_year.renewing_enrolled?
          organization.employer_profile.census_employees.non_terminated.each do |ce|
            ce.renewal_benefit_group_assignment.make_active 
          end

          plan_year.update_attributes(:aasm_state => 'active')
        end

        if plan_year.renewing_enrolling? && !plan_year.is_enrollment_valid?
          organization.employer_profile.census_employees.non_terminated.each do |ce|
            ce.renewal_benefit_group_assignment.make_active
          end         
        end

        create_initial_plan_year(organization, plan_year, termination_date)
        enrollments = enrollments_for_plan_year(plan_year)

        if enrollments.any?
          puts "Terminating employees coverage for employer #{organization.legal_name}"
        end

        enrollments.each do |hbx_enrollment|
          if plan_year.renewing_enrolling? && !plan_year.is_enrollment_valid?
            hbx_enrollment.cancel_coverage! if hbx_enrollment.may_cancel_coverage?
          elsif hbx_enrollment.may_terminate_coverage?
            hbx_enrollment.update_attributes(:terminated_on => termination_date)
            hbx_enrollment.terminate_coverage!
          end
        end

        if plan_year.renewing_enrolling? && !plan_year.is_enrollment_valid?
          plan_year.cancel_renewal! if plan_year.may_cancel_renewal?
        elsif plan_year.may_terminate?
          plan_year.update_attributes(:terminated_on => termination_date, :end_on => termination_date)
          plan_year.terminate!
        end

        if organization.employer_profile.may_revert_application?
          organization.employer_profile.revert_application! 
        end
      end
    end
  end
end

def create_initial_plan_year(organization, active_plan_year, termination_date)
  start_date = termination_date + 1.day
  new_plan_year = organization.employer_profile.plan_years.build({
    start_on: termination_date + 1.day,
    end_on: termination_date + 1.year,
    open_enrollment_start_on: start_date - 1.month,
    open_enrollment_end_on: Date.new(start_date.year, start_date.month - 1, 10),
    fte_count: active_plan_year.fte_count,
    pte_count: active_plan_year.pte_count,
    msp_count: active_plan_year.msp_count
    })

  new_plan_year.save!

  active_plan_year.benefit_groups.each do |active_group|
    new_group = clone_benefit_group(active_group, new_plan_year)
    if new_group.save
      CensusEmployee.by_benefit_group_ids([BSON::ObjectId.from_string(active_group.id.to_s)]).non_terminated.each do |ce|
        ce.add_benefit_group_assignment(new_group, new_plan_year.start_on)
      end
    else
      message = "Error saving benefit_group: #{new_group.id}, for employer: #{@employer_profile.id}"
      raise PlanYearRenewalFactoryError, message
    end
  end
end

def clone_benefit_group(active_group, new_plan_year)
  new_plan_year.benefit_groups.build({
    title: "#{active_group.title.titleize} New",
    effective_on_kind: active_group.effective_on_kind,
    terminate_on_kind: active_group.terminate_on_kind,
    plan_option_kind: active_group.plan_option_kind,
    default: active_group.default,
    effective_on_offset: active_group.effective_on_offset,
    employer_max_amt_in_cents: active_group.employer_max_amt_in_cents,
    relationship_benefits: active_group.relationship_benefits,
    reference_plan_id: active_group.reference_plan_id,
    elected_plan_ids: active_group.elected_plan_ids,
    is_congress: false
  })
end

def enrollments_for_plan_year(plan_year)
  id_list = plan_year.benefit_groups.map(&:id)
  families = Family.where(:"households.hbx_enrollments.benefit_group_id".in => id_list)
  enrollments = families.inject([]) do |enrollments, family|
    enrollments += family.active_household.hbx_enrollments.where(:benefit_group_id.in => id_list).any_of([HbxEnrollment::enrolled.selector, HbxEnrollment::renewing.selector]).to_a
  end
end