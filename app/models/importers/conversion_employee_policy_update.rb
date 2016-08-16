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
        # hired_on: {"$lte" => start_date},
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

      plan_years = employer.plan_years.select{|py| py.coverage_period_contains?(start_date) }
      plan_year = plan_years.detect{|py| (PlanYear::PUBLISHED + ['expired']).include?(py.aasm_state.to_s)}
   
      if plan_year.blank?
        errors.add(:base, "plan year missing")
        return false
      end

      enrollments = family.active_household.hbx_enrollments.where({
        :benefit_group_id.in => plan_year.benefit_group_ids,
        :aasm_state.in => HbxEnrollment::ENROLLED_STATUSES + HbxEnrollment::TERMINATED_STATUSES + ["coverage_expired"]
        }).by_coverage_kind('health').order(created_at: :desc).to_a

      if enrollments.empty?
        errors.add(:base, "enrollment missing!")
        return false
      end
  
      enrollment = enrollments.shift

      # if enrollments.size > 1
      #   errors.add(:base, "more than 1 enrollment found for given benefit groups")
      #   return false
      # end

      enrollments.each do |enrollment|
        enrollment.cancel_coverage!
      end

      enrollment.expire_coverage! if enrollment.may_expire_coverage?
      enrollment
    end

    def update_coverage_dependents(family, enrollment, employer, plan)
      census_dependents = map_dependents
      dependents = census_dependents.inject([]) do |dependents, dependent|
        dependents << Factories::EnrollmentFactory.initialize_dependent(enrollment.family, enrollment.subscriber.person, dependent)
      end.compact

      family.save!
      family.reload

      if enrollment.plan_id != plan.id
        enrollment.update_attributes(plan_id: plan.id)
      end

      enrollment.reload

      if update_enrollment_members(family, enrollment, dependents)         
        if passive_renewal = get_passively_renewed_coverage(employer, family)
          return passive_renewal if passive_renewal.is_a?(Boolean)
          update_enrollment_members(family, passive_renewal, dependents, true)

          renewal_plan = enrollment.plan.renewal_plan
          if passive_renewal.plan_id != renewal_plan.try(:id)
            passive_renewal.update_attributes(plan_id: renewal_plan.id)
          end
          
          return true
        else
          return false
        end
      else
        return false
      end
    end

    def get_passively_renewed_coverage(employer, family)
      renewed_plan_year = employer.renewing_published_plan_year
      if expired_plan_year = employer.plan_years.where(:aasm_state => 'expired').first
        renewed_plan_year = employer.plan_years.where({
          :start_on => (expired_plan_year.start_on + 1.year), 
          :aasm_state.in => PlanYear::RENEWING_PUBLISHED_STATE + PlanYear::PUBLISHED}).first
      end
    
      if renewed_plan_year.blank?
        errors.add(:base, "renewed/renewing plan year missing")
        return false
      end

      enrollments = family.active_household.hbx_enrollments.where({
        :benefit_group_id.in => renewed_plan_year.benefit_group_ids,
        :aasm_state.in => HbxEnrollment::ENROLLED_STATUSES + HbxEnrollment::TERMINATED_STATUSES + HbxEnrollment::RENEWAL_STATUSES
        }).by_coverage_kind('health')

      if enrollments.empty?
        errors.add(:base, "renewal enrollment missing!")
        return false
      end

      manual_selection = enrollments.detect{|e| e.workflow_state_transitions.where(:to_state => 'auto_renewing').none?}
      if manual_selection.present?
        warnings.add(:base, "employee already made plan selection")
        return true
      end

      if enrollments.size > 1
        errors.add(:base, "more than 1 passive renewal found for given benefit groups")
        return false
      end

      enrollments.first
    end

    def update_enrollment_members(family, enrollment, dependents, passive=false)
      update_msgs = []

      dependent_ids = dependents.map(&:id)
      updated_enrollment_members = enrollment.hbx_enrollment_members.inject([]) do |enrollment_members, enrollment_member|
        if enrollment_member.is_subscriber? || (enrollment_member.family_member.present? && dependent_ids.include?(enrollment_member.family_member.person_id))
          enrollment_members << enrollment_member
        else
          update_msgs << "Dropped #{enrollment_member.try(:family_member).try(:person).try(:full_name)} from the #{'renewed' if passive} enrollment"
          enrollment_members
        end
      end

      hh = family.active_household
      ch = hh.immediate_family_coverage_household
      dependents.each do |dependent|
        family_member = family.find_family_member_by_person(dependent)
        enrollment_member = updated_enrollment_members.detect{|enrollment_member| enrollment_member.applicant_id == family_member.id}
        if enrollment_member.blank?
          coverage_member = ch.coverage_household_members.detect{|cm| cm.family_member == family_member }
          if coverage_member.present?        
            updated_enrollment_members << HbxEnrollmentMember.new({
              applicant_id: family_member.id,
              eligibility_date: enrollment.effective_on,
              coverage_start_on: enrollment.effective_on
              })
            update_msgs << "Added #{family_member.person.full_name} to the #{'renewed' if passive} enrollment"
          else
            errors.add(:base, "Immediate coverage household member missing for #{family_member.person.full_name}")
          end
        end
      end

      enrollment.hbx_enrollment_members = updated_enrollment_members

      if enrollment.save
        warnings.add(:base, update_msgs.join(',')) if update_msgs.any?
        return true
      else
        enrollment.errors.each do |attr, err|
          errors.add("family_" + attr.to_s, err)
        end
        return false
      end
    end

    def map_dependent(dep_idx)
      last_name = self.send("dep_#{dep_idx}_name_last".to_sym)
      first_name = self.send("dep_#{dep_idx}_name_first".to_sym)
      middle_name = self.send("dep_#{dep_idx}_name_middle".to_sym)
      relationship = self.send("dep_#{dep_idx}_relationship".to_sym)
      dob = self.send("dep_#{dep_idx}_dob".to_sym)
      ssn = self.send("dep_#{dep_idx}_ssn".to_sym)
      gender = self.send("dep_#{dep_idx}_gender".to_sym)
      if [first_name, last_name, middle_name, relationship, dob, ssn, gender].all?(&:blank?)
        return nil
      end
      attr_hash = {
        first_name: first_name,
        last_name: last_name,
        dob: dob,
        employee_relationship: relationship,
        gender: gender
      }
      unless middle_name.blank?
        attr_hash[:middle_name] = middle_name
      end
      unless ssn.blank?
        if ssn == subscriber_ssn
          warnings.add("dependent_#{dep_idx}_ssn", "ssn same as subscriber, blanking for import")
        else
          attr_hash[:ssn] = ssn
        end
      end
      CensusDependent.new(attr_hash)
    end

    def map_dependents
      (1..8).to_a.map do |idx|
        map_dependent(idx)
      end.compact
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
      begin
        return false unless valid?
        employer = find_employer

        person = find_person
        return false unless person

        puts '----processing ' + person.full_name
        family = person.primary_family
        enrollment = find_current_enrollment(family, employer)

        return false unless enrollment

        plan = find_plan
        return false unless update_coverage_dependents(family, enrollment, employer, plan)

        if enrollment.plan_id != plan.id
          enrollment.update_attributes(plan_id: plan.id)
          if renewing_plan_year = employer.plan_years.renewing.first
            update_plan_for_passive_renewal(family, renewing_plan_year, plan.renewal_plan)
          end
          return true
        else
          errors.add(:base, "already have coverage with same hios id")
          return false
        end
      rescue Exception => e
        errors.add(:base, e.to_s)
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
