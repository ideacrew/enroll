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
        return
      end

      valid_enrollment = selected_enrollments.first

      if valid_enrollment.present?
        renewal_enrollments.first.cancel_coverage!
      else
        valid_enrollment = renewal_enrollments.first
      end
      
      valid_enrollment.advance_date! if valid_enrollment.may_advance_date?

      # TODO: handle case where enrollment effective_on is on future date
      valid_enrollment.is_coverage_waived? ? valid_enrollment.benefit_group_assignment.waive_benefit : valid_enrollment.benefit_group_assignment.begin_benefit
    end

    def end_coverage
      enrollments.each do |enrollment|
        enrollment.advance_date! if enrollment.may_advance_date?
        enrollment.benefit_group_assignment.expire_coverage! if enrollment.benefit_group_assignment.may_expire_coverage!
        enrollment.benefit_group_assignment.update_attributes(is_active: false) if enrollment.benefit_group_assignment.is_active?
      end
    end

    private

    def enrollments
      family_record.active_household.hbx_enrollments.where(effective_on: (@plan_year.start_on..@plan_year.end_on)).shop_market
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