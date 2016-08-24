module Factories
  class CensusEmployeeFactory

    attr_accessor :census_employee, :plan_year
    def begin_coverage

      if selected_enrollments.size > 1
        raise CensusEmployeeFactoryError, "More then one active enrollment selected for the coverage year"
      end

      if renewal_enrollments.size > 1
        raise CensusEmployeeFactoryError, "More then one renewal enrollment found for the coverage year"
      end

      if selected_enrollments.none? && renewal_enrollments.none?
        # TODO: update benefit group assignment to correct state from coverage_renewing
        
        bg_ids = @plan_year.benefit_groups.map(&:id)
        assignment = @census_employee.benefit_group_assignments.detect{ |assignment| bg_ids.include?(assignment.benefit_group_id) }

        if assignment.present?
          assignment.make_active
        else
          benefit_group = @plan_year.default_benefit_group || @plan_year.benefit_groups.first
          census_employee.add_benefit_group_assignment(benefit_group, benefit_group.start_on)
          census_employee.save!
        end

        return
      end

      if selected_enrollments.size == 1 && renewal_enrollments.size == 1
        hbx_enrollment = selected_enrollments.first
        renewal_enrollment = renewal_enrollments.first

        if valid_enrollment?(hbx_enrollment, renewal_enrollment)
          hbx_enrollment.begin_coverage! if hbx_enrollment.may_begin_coverage?
          hbx_enrollment.benefit_group_assignment.begin_benefit
          renewal_enrollment.cancel_coverage!
        else
          raise PlanYearPublishFactoryError, "Hbx enrollment can't be enrolled updated_at #{hbx_enrollment.updated_at.strftime('%m-%d-%Y')}"
        end
      end

      hbx_enrollment = selected_enrollments.first
      hbx_enrollment = renewal_enrollments.first if hbx_enrollment.blank?

      if hbx_enrollment.effective_on <= TimeKeeper.date_of_record
        hbx_enrollment.begin_coverage! if hbx_enrollment.may_begin_coverage?
        if hbx_enrollment.benefit_group_assignment.present?
          hbx_enrollment.is_coverage_waived? ? hbx_enrollment.benefit_group_assignment.waive_benefit : hbx_enrollment.benefit_group_assignment.begin_benefit
        end
      end
    end

    def valid_enrollment?(hbx_enrollment, renewal_enrollment)
      hbx_enrollment.effective_on == renewal_enrollment.effective_on && hbx_enrollment.effective_on <= TimeKeeper.date_of_record
    end

    def end_coverage
      prev_year_enrollments = employee_enrollments.select{|enrollment| enrollment.benefit_group == @plan_year.benefit_groups.first}.select{|e| HbxEnrollment::ENROLLED_STATUSES.include?(e.aasm_state)}
      prev_year_enrollments.each do |hbx_enrollment|
        hbx_enrollment.expire_coverage! if hbx_enrollment.may_expire_coverage?
        benefit_group_assignment = hbx_enrollment.benefit_group_assignment
        benefit_group_assignment.expire_coverage! if benefit_group_assignment.may_expire_coverage?
        benefit_group_assignment.update_attributes(is_active: false) if benefit_group_assignment.is_active?
      end
    end

    private

    def employee_enrollments
      family_record.active_household.hbx_enrollments
    end

    def enrollments
      employee_enrollments.where(effective_on: (@plan_year.start_on..@plan_year.end_on)).shop_market
    end

    def selected_enrollments
      enrollments.enrolled
    end

    def renewal_enrollments
      enrollments.renewing + enrollments.where(:aasm_state.in => ["renewing_waived"])
    end

    # TODO: DO WE NEED TO CREATE FAMILY?
    def family_record
      family = person_record.primary_family

      if family.blank?
        raise CensusEmployeeFactoryError, "No family match found!!"
      end

      family
    end

    # TODO: FIX PERSON MATCHING LOGIC
    def person_record
      if @census_employee.employee_role.blank?
        employee_relationship = Forms::EmployeeCandidate.new({
          first_name: @census_employee.first_name,
          last_name: @census_employee.last_name,
          ssn: @census_employee.ssn,
          dob: @census_employee.dob.strftime("%Y-%m-%d")
        })

        person = employee_relationship.match_person

        if person.blank?
          raise CensusEmployeeFactoryError, "No person match found!!"
        end
      else
        person = @census_employee.employee_role.person
      end

      person
    end
  end

  class CensusEmployeeFactoryError < StandardError; end
end
