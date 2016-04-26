module Importers
  class ConversionEmployeePolicy
    include ActiveModel::Validations
    include ActiveModel::Model

    attr_reader :warnings, :fein, :subscriber_ssn, :subscriber_dob, :benefit_begin_date

    attr_accessor :action,
      :default_policy_start,
      :hios_id,
      :plan_year

    include ValueParsers::OptimisticSsnParser.on(:subscriber_ssn, :fein)

    validate :validate_benefit_group_assignment
    validate :validate_census_employee
    validate :validate_fein
    validate :validate_plan
    validates_length_of :fein, is: 9
    validates_length_of :subscriber_ssn, is: 9
    validates_presence_of :hios_id

    def initialize(opts = {})
      super(opts)
      @warnings = ActiveModel::Errors.new(self)
    end

    def subscriber_dob=(val)
      @subscriber_dob = val.blank? ? nil : (Date.strptime(val, "%m/%d/%Y") rescue nil)
    end

    def benefit_begin_date=(val)
      @benefit_begin_date = val.blank? ? nil : (Date.strptime(val, "%m/%d/%Y") rescue nil)
    end

    def start_date
      [default_policy_start].detect { |item| !item.blank? }
    end

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

    def save
      return false unless valid?
      employer = find_employer
      employee = find_employee
      plan = find_plan
      bga = find_benefit_group_assignment
      person_data = PersonSlug.new(nil, employee.first_name, employee.middle_name,
                                   employee.last_name, employee.name_sfx,
                                   employee.ssn,
                                   employee.dob,
                                   employee.gender)
      role, family = Factories::EnrollmentFactory.construct_employee_role(nil, employee, person_data)
      if role.nil? && family.nil?
         errors.add(:base, "matching conflict for this personal data")
         return false
      end
      unless role.person.save
        role.person.errors.each do |attr, err|
          errors.add("employee_role_" + attr.to_s, err)
        end
        return false
      end
      unless family.save
        family.errors.each do |attr, err|
          errors.add("family_" + attr.to_s, err)
        end
        return false
      end
      hh = family.active_household
      ch = hh.immediate_family_coverage_household
      en = hh.new_hbx_enrollment_from({
        coverage_household: ch,
        employee_role: role,
        benefit_group: bga.benefit_group,
        benefit_group_assignment: bga
      })
      en.effective_on = start_date
      en.external_enrollment = true
      en.hbx_enrollment_members.each do |mem|
        mem.eligibility_date = start_date
        mem.coverage_start_on = start_date
      end
      en.save!
      en.update_attributes!({
        carrier_profile_id: plan.carrier_profile_id,
        plan_id: plan.id,
        aasm_state: "coverage_selected",
        coverage_kind: 'health'
      })
      true
    end
  end
end
