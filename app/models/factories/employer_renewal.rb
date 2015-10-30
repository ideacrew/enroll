module Factories
  class EmployerRenewal
    include Mongoid::Document

    EARLIEST_RENEWAL_START_ON = HbxProfile::ShopMaximumRenewalPeriodBeforeStartOn

    def initialize(employer_profile)

      @employer_profile = employer_profile
      validate_employer_profile
      project_renewal_dates
      qualify_application


    end

    def validate_employer_profile

      unless PlanYear::PUBLISHED.include? @employer_profile.active_plan_year.aasm_state
        raise EmployerRenewalError, "Renewals require an existing, published Plan Year"
      end

      unless TimeKeeper.date_of_record <= @employer_profile.plan_year.end_on
        raise EmployerRenewalError, "Renewal time period has expired.  You must submit a new application"
      end

      unless @employer_profile.is_primary_office_local?
        raise EmployerRenewalError, "Employer primary address must be located in #{HbxProfile.StateName}"
      end
    end

    def renew_employer_profile(employer_profile)
      @employer_profile = employer_profile
      @active_plan_year = @employer_profile.active_plan_year

      @renewal_plan_year = renew_plan_year
    end

    def self.auto_renew_employee_roles(employer_profile)
    end

    def qualify_application
      # Primary Address is DC
      # At least one non-owner
      # Minimum participation ratio
    end

    def renew_plan_year
      new_plan_year = PlanYear.new
      new_plan_year.start_on = @active_plan_year.start_on + 1.year
      new_plan_year.end_on = @active_plan_year.end_on + 1.year
      new_plan_year.open_enrollment_start_on = @active_plan_year.open_enrollment_start_on + 1.year
      new_plan_year.open_enrollment_end_on = @active_plan_year.open_enrollment_end_on + 1.year

      new_plan_year.fte_count = @active_plan_year.fte_count
      new_plan_year.pte_count = @active_plan_year.pte_count
      new_plan_year.msp_count = @active_plan_year.msp_count

      new_plan_year.benefit_groups = renew_benefit_groups
      new_plan_year.renew
      new_plan_year
    end

    def renew_benefit_groups
      count = 1
      @active_plan_year.benefit_groups.reduce([]) do |list, active_group|
        new_year = @active_plan_year.start_on.year + 1
        new_group = BenefitGroup.new
        new_group.title = "Benefit Package #{new_year} ##{count} (#{active_group.title})"

        new_group.effective_on_kind = active_group.effective_on_kind
        new_group.terminate_on_kind = active_group.terminate_on_kind
        new_group.plan_option_kind = active_group.plan_option_kind

        new_group.reference_plan_id = map_benefit(active_group.reference_plan_id)
        new_group.lowest_cost_plan_id = map_benefit(active_group.lowest_cost_plan_id)
        new_group.highest_cost_plan_id = map_benefit(active_group.highest_cost_plan_id)

        new_group.elected_plan_ids = active_group.elected_plan_ids.reduce([]) {|id_list, id| id_list << map_benefit(id) }
        new_group.relationship_benefits = active_group.relationship_benefits
        count += 1
        list << new_group
      end
    end

    def build_benefits_map
      {
        :"92479DC0020002" => "92479DC0020024", 
        :"92479DC0020011" => "92479DC0020012"
      }
    end

    def eligible_employees
      @active_plan_year.eligible_to_enroll
    end

    def auto_renew_employee_role_benefits(employee_role)

    end

    # Identify benefits in new period comparable to current benefit
    def map_benefit(current_benefit_id)

    end

    def generate_employee_role_notices
    end

    def generate_employer_profile_notices
    end

  end
end

class EmployerRenewalError < StandardError; end
