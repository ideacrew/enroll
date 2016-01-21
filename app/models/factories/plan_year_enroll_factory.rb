module Factories
  class PlanYearEnrollFactory

    attr_accessor :employer_profile, :start_on

    def enroll
      published_plan_years = @employer_profile.plan_years.where(:"start_on" => start_on).any_of([PlanYear.published.selector, PlanYear.renewing_published_state.selector])

      if published_plan_years.size == 0
        raise PlanYearPublishFactoryError, "Found zero Renewal/Published Plan Years for Employer #{@employer_profile.legal_name}"
      end

      if published_plan_years.size > 1
        raise PlanYearPublishFactoryError, "Found more than one Renewal/Published Plan Years for Employer #{@employer_profile.legal_name}"
      end

      @count = 0
      @employer_profile.census_employees.each do |census_employee|
        begin
          begin_employee_coverage(census_employee)
        rescue Exception => e
          puts "Exception #{e.inspect}"
        end
      end

      published_plan_years.each do |plan_year|
        plan_year.activate! if plan_year.may_activate?          
      end

      @employer_profile.plan_years.published.where(:start_on => (start_on - 1.year)).each do |plan_year|
        plan_year.expire! if plan_year.may_expire?          
      end

      puts "Processed #{@employer_profile.census_employees.count} census employees, skipped #{@count} census employee records"
    end


    def begin_employee_coverage(census_employee)
      puts "Processing #{census_employee.full_name}"

      if census_employee.renewal_benefit_group_assignment.present?
        benefit_group_assignment = census_employee.renewal_benefit_group_assignment
        benefit_group_assignment.select_coverage! if benefit_group_assignment.may_select_coverage?            
        benefit_group_assignment.make_benefit_group_assignment_active
      end

      if census_employee.employee_role.blank?
        employee_relationship = Forms::EmployeeCandidate.new({
          first_name: census_employee.first_name,
          last_name: census_employee.last_name,
          ssn: census_employee.ssn,
          dob: census_employee.dob.strftime("%Y-%m-%d")
          })

        person = employee_relationship.match_person

        if person.blank?
          @count += 1
          return
        end
      else
        person = census_employee.employee_role.person
      end

      family = person.primary_family
      if family.blank?
        raise PlanYearPublishFactoryError, "No family exists for #{census_employee.full_name}"
      end

      if family.active_household.hbx_enrollments.show_enrollments.current_year.size > 1
        @count += 1 
        raise PlanYearPublishFactoryError, "Found more than one enrollment for #{census_employee.full_name}"
      end

      # if family.active_household.hbx_enrollments.renewing.size > 1
      #   raise PlanYearPublishFactoryError, "Found more than one renewal enrollment for census employee #{census_employee.full_name}"
      # end

      family.active_household.hbx_enrollments.each do |hbx_enrollment|
        if hbx_enrollment.effective_on <= TimeKeeper.date_of_record
          hbx_enrollment.expire_coverage! if hbx_enrollment.may_expire_coverage?

          if hbx_enrollment.benefit_group_assignment && hbx_enrollment.benefit_group_assignment.may_expire_coverage?
            hbx_enrollment.benefit_group_assignment.expire_coverage!
          end
        end
      end

      family.active_household.hbx_enrollments.renewing.each do |hbx_enrollment|
        if hbx_enrollment.effective_on <= TimeKeeper.date_of_record
          hbx_enrollment.begin_coverage!
        end
      end

      puts "Processed #{census_employee.full_name}"
    end
  end

  class PlanYearPublishFactoryError < StandardError; end
end

