module Factories
  class EmployerProfilePlanYearRenewal
    include Mongoid::Document

    EARLIEST_RENEWAL_START_ON = HbxProfile::ShopMaximumRenewalPeriodBeforeStartOn

    attr_accessor :employer_profile

    def renew
      @employer_profile = employer_profile


      validate_employer_profile

      @active_plan_year = @employer_profile.active_plan_year

      # Set renewal open enrollment period
      open_enrollment_start_on = Date.new((@active_plan_year.open_enrollment_end_on + 1.year - 1.day).year,
                                           @active_plan_year.open_enrollment_end_on.month,
                                           1)

      open_enrollment_end_on = Date.new((@active_plan_year.open_enrollment_end_on + 1.year).year,
                                         @active_plan_year.open_enrollment_end_on.month,
                                         @active_plan_year.ShopRenewalOpenEnrollmentEndDueDayOfMonth)


      @renewal_plan_year = @employer_profile.plan_years.build({
        start_on: @active_plan_year.start_on + 1.year,
        end_on: @active_plan_year.end_on + 1.year,
        open_enrollment_start_on: open_enrollment_start_on,
        open_enrollment_end_on: open_enrollment_end_on,
        fte_count: @active_plan_year.fte_count,
        pte_count: @active_plan_year.pte_count,
        msp_count: @active_plan_year.msp_count
      })

      if @renewal_plan_year.may_renew_plan_year?
        @renewal_plan_year.renew_plan_year 
      else
        raise EmployerProfilePlanYearRenewalError, 
          "For employer: #{@employer_profile.inspect}, \n"\
          "PlanYear state: #{@renewal_plan_year.aasm_state} cannot transition to renewing_draft"\
      end

      if @renewal_plan_year.save
        renew_benefit_groups
        @renewal_plan_year
      else
        raise EmployerProfilePlanYearRenewalError, 
          "For employer: #{@employer_profile.inspect}, \n" \
          "Error(s): \n #{@renewal_plan_year.errors.map{|k,v| "#{k} = #{v}"}.join(" & \n")} \n" \
          "Unable to save renewal plan year: #{@renewal_plan_year.inspect}"
      end
    end

  private
    def validate_employer_profile
      unless PlanYear::PUBLISHED.include? @employer_profile.active_plan_year.aasm_state
        raise EmployerProfilePlanYearRenewalError, "Renewals require an existing, published Plan Year"
      end

      unless TimeKeeper.date_of_record <= @employer_profile.active_plan_year.end_on
        raise EmployerProfilePlanYearRenewalError, "Renewal time period has expired.  You must submit a new application"
      end

      unless @employer_profile.is_primary_office_local?
        raise EmployerProfilePlanYearRenewalError, "Employer primary address must be located in #{HbxProfile.StateName}"
      end
    end

    def renew_benefit_groups
      @active_plan_year.benefit_groups.each do |active_group|
        new_group = clone_benefit_group(active_group)
        if new_group.save
          renew_census_employees(active_group, new_group)
        else
          raise EmployerProfilePlanYearRenewalError, "For employer: #{@employer_profile.inspect}, unable to save benefit_group: #{new_group.inspect}"
        end
      end
    end

    def clone_benefit_group(active_group)
      index = @active_plan_year.benefit_groups.index(active_group) + 1
      new_year = @active_plan_year.start_on.year + 1

      reference_plan_id = Plan.find(active_group.reference_plan_id).renewal_plan_id
      if reference_plan_id.blank?
        raise EmployerProfilePlanYearRenewalError, "Unable to find renewal for referenence plan: #{active_group.reference_plan}"
      end

      elected_plan_ids  = Plan.where(:id.in => active_group.elected_plan_ids).map(&:renewal_plan_id)
      if elected_plan_ids.blank?
        raise EmployerProfilePlanYearRenewalError, "Unable to find renewal for elected plans: #{active_group.elected_plan_ids}"
      end

      @renewal_plan_year.benefit_groups.build({
        title: "Benefit Package #{new_year} ##{index} (#{active_group.title})",
        effective_on_kind: "first_of_month",
        terminate_on_kind: active_group.terminate_on_kind,
        plan_option_kind: active_group.plan_option_kind,
        default: active_group.default,
        effective_on_offset: active_group.effective_on_offset,
        employer_max_amt_in_cents: active_group.employer_max_amt_in_cents,
        relationship_benefits: active_group.relationship_benefits,

        reference_plan_id: reference_plan_id,
        elected_plan_ids: elected_plan_ids
      })
    end

    def renew_census_employees(active_group, new_group)
      eligible_employees(active_group).each do |census_employee|
        if census_employee.active_benefit_group_assignment && census_employee.active_benefit_group_assignment.benefit_group_id == active_group.id
          census_employee.add_renew_benefit_group_assignment(new_group)
          
          unless census_employee.save 
            raise EmployerProfilePlanYearRenewalError, "For employer: #{@employer_profile.inspect}, unable to save census_employee: #{census_employee.inspect}"
          end
        end
      end
      true
    end

    def eligible_employees(active_group)
      CensusEmployee.by_benefit_group_ids([BSON::ObjectId.from_string(active_group.id.to_s)]).active
    end

    def generate_employee_role_notices
    end

    def generate_employer_profile_notices
    end

  end
end

class EmployerProfilePlanYearRenewalError < StandardError; end
