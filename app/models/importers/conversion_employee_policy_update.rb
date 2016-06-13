module Importers
  class ConversionEmployeePolicyUpdate < ConversionEmployeePolicyCommon

    validate :validate_benefit_group_assignment
    validate :validate_census_employee
    validate :validate_fein
    validate :validate_plan
    validates_length_of :fein, is: 9
    validates_length_of :subscriber_ssn, is: 9
    validates_presence_of :hios_id

    def validate_fein
      return true if fein.blank?
      found_employer = find_employer
      if found_employer.nil?
        errors.add(:fein, "does not exist")
      end
    end

    def validate_census_employee
      return true if subscriber_ssn.blank?
      found_employee = find_employee
      if found_employee.nil?
        errors.add(:subscriber_ssn, "no census employee found")
      end
    end

    def validate_benefit_group_assignment
      return true if subscriber_ssn.blank?
      found_employee = find_employee
      return true unless find_employee
      found_bga = find_benefit_group_assignment
      if found_bga.nil?
        errors.add(:subscriber_ssn, "no benefit group assignment found")
      end
    end

    def validate_plan
      return true if hios_id.blank?
      found_plan = find_plan
      if found_plan.nil?
        errors.add(:hios_id, "no plan found with hios_id #{hios_id} and active year #{plan_year}")
      end
    end

    def find_benefit_group_assignment
      return @found_benefit_group_assignment unless @found_benefit_group_assignment.nil?
      census_employee = find_employee
      return nil unless census_employee
      candidate_bgas = census_employee.benefit_group_assignments.select do |bga|
        bga.start_on <= start_date
      end
      non_terminated_employees = candidate_bgas.reject do |ce|
        (!ce.end_on.blank?) && ce.end_on <= Date.today
      end
      @found_benefit_group_assignment = non_terminated_employees.sort_by(&:start_on).last
    end

    def find_employee
      return @found_employee unless @found_employee.nil?
      return nil if subscriber_ssn.blank?
      found_employer = find_employer
      return nil if found_employer.nil?
      candidate_employees = CensusEmployee.where({
        employer_profile_id: found_employer.id,
        hired_on: {"$lte" => start_date},
        encrypted_ssn: CensusMember.encrypt_ssn(subscriber_ssn)
      })
      non_terminated_employees = candidate_employees.reject do |ce|
        (!ce.employment_terminated_on.blank?) && ce.employment_terminated_on <= Date.today
      end
    
      @found_employee = non_terminated_employees.sort_by(&:hired_on).last
    end

    def find_plan 
      return @plan unless @plan.nil?
      return nil if hios_id.blank?
      clean_hios = hios_id.strip
      corrected_hios_id = (clean_hios.end_with?("-01") ? clean_hios : clean_hios + "-01")
      @plan = Plan.where({
        active_year: plan_year.to_i,
        hios_id: corrected_hios_id
      }).first
    end

    def find_employer
      return @found_employer unless @found_employer.nil?
      org = Organization.where(:fein => fein).first
      return nil unless org
      @found_employer = org.employer_profile
    end

    PersonSlug = Struct.new(:name_pfx, :first_name, :middle_name, :last_name, :name_sfx, :ssn, :dob, :gender)

    def find_person
      employee = find_employee

      role = employee.employee_role
      person = role.try(:person)

      if person.blank?
        people = Person.where(:'employee_roles.census_employee_id' => employee.id)

        if people.size > 1
          errors.add(:base, "found mutliple people linked to the census employee record")
          return false
        end

        person = people.first
      end

      if person.blank?
        errors.add(:base, "unable to find person")
        return false
      end

      person
    end

    def find_current_enrollment(family, employer)
      plan_year = employer.plan_years.published_plan_years_by_date(benefit_begin_date).first || employer.plan_years.published.first
  
      if plan_year.blank?
        errors.add(:base, "plan year missing")
        return false
      end

      enrollments = family.active_household.hbx_enrollments.where({
        :benefit_group_id.in => plan_year.benefit_group_ids,
        :aasm_state.in => HbxEnrollment::ENROLLED_STATUSES + HbxEnrollment::TERMINATED_STATUSES
        })

      if enrollments.empty?
        errors.add(:base, "enrollment missing!")
        return false
      end

      if enrollments.size > 1
        errors.add(:base, "more than 1 enrollment found for given benefit groups")
        return false
      end

      enrollments[0]
    end

    def update_plan_for_passive_renewal(family, renewing_plan_year, renewal_plan)
      enrollments = family.active_household.hbx_enrollments.where(:benefit_group_id.in => renewing_plan_year.benefit_group_ids)

      if enrollments.enrolled.present?
        errors.add(:base, "employee already made plan selection")
        return false
      end

      if enrollments.renewing.size > 1
        errors.add(:base, "duplicate passive renewals found!")
        return false        
      end

      if enrollments.renewing.blank?
        return true
      else
        if renewal_plan.blank?
          errors.add(:base, "renewal plan missing!")
          return false  
        end
        enrollments.renewing.first.update_attributes(plan_id: renewal_plan.id)
        return true
      end
    end

    def save
      return false unless valid?
      employer = find_employer

      person = find_person
      return false unless person

      puts '----processing ' + person.full_name
      family = person.primary_family
      enrollment = find_current_enrollment(family, employer)
      return false unless enrollment

      plan = find_plan
      if enrollment.plan_id != plan.id
        enrollment.update_attributes(plan_id: plan.id)

        if renewing_plan_year = employer.plan_years.renewing.first
          update_plan_for_passive_renewal(family, renewing_plan_year, plan.renewal_plan)
        end
      else
        errors.add(:base, "already have coverage with same hios id")
        return false
      end
    end

    def cancel_other_enrollments_for_bga(bga)
      enrollments = HbxEnrollment.find_shop_and_health_by_benefit_group_assignment(bga)
      enrollments.each do |en|
        en.hbx_enrollment_members.each do |hen|
           hen.coverage_end_on = hen.coverage_start_on
        end
        en.terminated_on = en.effective_on
        en.aasm_state = "coverage_canceled"
        en.save!
      end
    end
  end
end
