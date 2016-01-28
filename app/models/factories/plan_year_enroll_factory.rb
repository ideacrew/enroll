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
          census_employee.is_active? ? begin_employee_coverage(census_employee) : terminate_employee_coverage(census_employee)
          puts "Processed #{census_employee.full_name}"
        rescue Exception => e
          puts "Exception #{e.inspect} occured for #{census_employee.full_name}"
        end
      end

      published_plan_years.each{ |plan_year| plan_year.activate! }
      @employer_profile.plan_years.published.where(:start_on => (start_on - 1.year)).each do |plan_year|
        plan_year.expire!
      end

      puts "Processed #{@employer_profile.census_employees.count} census employees, skipped #{@count} census employee records"
    end

    def begin_employee_coverage(census_employee)
      person = match_person(census_employee)
      family = person.primary_family

      if family.blank?
        @count += 1
        raise PlanYearPublishFactoryError, "Family don't exist!!"
      end

      current_year_enrollments = family.active_household.hbx_enrollments.current_year.shop_market

      enrolled_enrollments = current_year_enrollments.enrolled
      renewing_enrollments = current_year_enrollments.renewing + current_year_enrollments.where(:aasm_state.in => ["renewing_waived"])

      if enrolled_enrollments.size > 1 || renewing_enrollments.size > 1
        @count += 1 
        raise PlanYearPublishFactoryError, "More than one #{TimeKeeper.date_of_record.year} coverage found!!"
      end

      if enrolled_enrollments.size == 1 && renewing_enrollments.size == 1
        hbx_enrollment = enrolled_enrollments.first
        renewal_hbx_enrollment = renewing_enrollments.first

        if hbx_enrollment.effective_on == renewal_hbx_enrollment.effective_on && hbx_enrollment.effective_on <= TimeKeeper.date_of_record && hbx_enrollment.updated_at < TimeKeeper.date_of_record.beginning_of_year
          puts "Canceled renewal policy for #{census_employee.full_name}"

          hbx_enrollment.begin_coverage!
          hbx_enrollment.benefit_group_assignment.select_coverage! unless hbx_enrollment.benefit_group_assignment.coverage_selected?
          hbx_enrollment.benefit_group_assignment.update_attributes(is_active: true)

          renewal_hbx_enrollment.cancel_coverage!
        else
          @count += 1
          raise PlanYearPublishFactoryError, "Hbx enrollment can't be enrolled updated_at #{hbx_enrollment.updated_at.strftime('%m-%d-%Y')}"
        end
      elsif enrolled_enrollments.size.zero?
        renewing_enrollments.each do |hbx_enrollment|
          if hbx_enrollment.effective_on <= TimeKeeper.date_of_record
            hbx_enrollment.begin_coverage!
            hbx_enrollment.benefit_group_assignment.select_coverage! unless hbx_enrollment.benefit_group_assignment.coverage_selected?
            hbx_enrollment.benefit_group_assignment.update_attributes(is_active: true)
          end
        end
      end

      expire_previous_year_enrollments(family)
    end

    def terminate_employee_coverage(census_employee)
      return
      person = match_person(census_employee)
      family = person.primary_family

      return unless family.present?

      cancel_renewals(family)
      expire_previous_year_enrollments(family)
    end

    private

    def match_person(census_employee)
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
          raise PlanYearPublishFactoryError, "No person match found!!"
        end
      else
        person = census_employee.employee_role.person
      end

      return person
    end
    
    # Question: Can we cancel other 2016 shop enrollments if any?
    def cancel_renewals(family)
      shop_enrollments = family.active_household.hbx_enrollments.shop_market.current_year

      (shop_enrollments.renewing + shop_enrollments.where(:aasm_state.in => ["renewing_waived"])).each do |hbx_enrollment|
        hbx_enrollment.cancel_coverage!
        hbx_enrollment.benefit_group_assignment.terminate_coverage! if hbx_enrollment.benefit_group_assignment.may_terminate_coverage?
        hbx_enrollment.benefit_group_assignment.update_attributes(is_active: false)
      end
    end

    def expire_previous_year_enrollments(family)
      prev_year_enrollments = family.active_household.hbx_enrollments.by_year(TimeKeeper.date_of_record.year - 1).shop_market
      prev_year_enrollments.enrolled.each do |hbx_enrollment|
        hbx_enrollment.expire_coverage! unless hbx_enrollment.coverage_expired?
        hbx_enrollment.benefit_group_assignment.expire_coverage! if hbx_enrollment.benefit_group_assignment.may_expire_coverage?
        hbx_enrollment.benefit_group_assignment.update_attributes(is_active: false)
      end
    end
  end
   

  class PlanYearPublishFactoryError < StandardError; end
end

