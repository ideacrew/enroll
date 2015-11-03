module Factories
  class EmployerRenewal
    include Mongoid::Document

    EARLIEST_RENEWAL_START_ON = HbxProfile::ShopMaximumRenewalPeriodBeforeStartOn

    def initialize(employer_profile)
      @employer_profile = employer_profile
      # project_renewal_dates
    end

    def validate_employer_profile
      unless PlanYear::PUBLISHED.include? @employer_profile.active_plan_year.aasm_state
        raise EmployerRenewalError, "Renewals require an existing, published Plan Year"
      end

      unless TimeKeeper.date_of_record <= @employer_profile.active_plan_year.end_on
        raise EmployerRenewalError, "Renewal time period has expired.  You must submit a new application"
      end

      unless @employer_profile.is_primary_office_local?
        raise EmployerRenewalError, "Employer primary address must be located in #{HbxProfile.StateName}"
      end
    end

    def build
      validate_employer_profile

      @active_plan_year = @employer_profile.active_plan_year
      @renew_plan_year = @employer_profile.plan_years.build({
        start_on: @active_plan_year.start_on + 1.year,
        end_on: @active_plan_year.end_on + 1.year,
        open_enrollment_start_on: @active_plan_year.open_enrollment_start_on + 1.year,
        open_enrollment_end_on: @active_plan_year.open_enrollment_end_on + 1.year,
        fte_count: @active_plan_year.fte_count,
        pte_count: @active_plan_year.pte_count,
        msp_count: @active_plan_year.msp_count
      })

      @renew_plan_year.renew
      @renew_plan_year.save!

      renew_benefit_groups
    end

    def renew_benefit_groups
      @active_plan_year.benefit_groups.each do |benefit_groups, active_group|
        new_group = clone_benefit_group(active_group)
        new_group.save!
        renew_census_employees(active_group, new_group)
      end
    end

    def clone_benefit_group(active_group)
      index = @active_plan_year.benefit_groups.index(active_group) + 1
      new_year = @active_plan_year.start_on.year + 1

      @renew_plan_year.benefit_groups.build({
        title: "Benefit Package #{new_year} ##{index} (#{active_group.title})",
        effective_on_kind: active_group.effective_on_kind,
        terminate_on_kind: active_group.terminate_on_kind,
        reference_plan_id: Plan.find(active_group.reference_plan_id).renewal_plan_id,
        plan_option_kind: active_group.plan_option_kind,
        elected_plan_ids: Plan.where(:id.in => active_group.elected_plan_ids).map(&:renewal_plan_id),
        relationship_benefits: active_group.relationship_benefits
      })
    end

    def renew_census_employees(active_group, new_group)
      census_employees = CensusEmployee.by_benefit_group_ids([BSON::ObjectId.from_string(active_group.id.to_s)]).active
      census_employees.each do |census_employee|
        if census_employee.active_benefit_group_assignment && census_employee.active_benefit_group_assignment.benefit_group_id == active_group.id
          census_employee.add_renew_benefit_group_assignment(new_group)
          census_employee.save!
        end
      end
      true
    end

    def self.auto_renew_employee_roles(employer_profile)
    end

    def eligible_employees
      @active_plan_year.eligible_to_enroll
    end

    def auto_renew_employee_role_benefits(employee_role)

    end

    def generate_employee_role_notices
    end

    def generate_employer_profile_notices
    end

  end
end

class EmployerRenewalError < StandardError; end
