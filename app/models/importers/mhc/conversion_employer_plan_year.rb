module Importers::Mhc
  class ConversionEmployerPlanYear < Importers::ConversionEmployerPlanYear

    CARRIER_MAPPING = {
      "bmc healthnet plan"=>"BMCHP", 
      "fallon health"=>"FCHP", 
      "health new england"=>"HNE"
    }

    validate :validate_plan_selection

    attr_accessor :employee_only_rt_contribution,
      :employee_only_rt_premium,
      :employee_and_spouse_rt_offered,
      :employee_and_spouse_rt_contribution,
      :employee_and_spouse_rt_premium,
      :employee_and_one_or_more_dependents_rt_offered,
      :employee_and_one_or_more_dependents_rt_contribution,
      :employee_and_one_or_more_dependents_rt_premium,
      :family_rt_offered,
      :family_rt_contribution,
      :family_rt_premium

    def plan_selection=(val)
      @plan_selection = val.to_s.parameterize('_')
    end

    def validate_plan_selection
      if plan_selection != 'sole_source'
        errors.add(:plan_selection, "invalid plan selection specified (not sole source)")
      end
    end

    def select_reference_plan(available_plans)
      if plan_selection == 'sole_source'
        if !single_plan_hios_id.blank?
          sp_hios = single_plan_hios_id.strip
          found_sole_source_plan = available_plans.detect { |pl| (pl.hios_id == sp_hios) || (pl.hios_id == "#{sp_hios}-01") }
          return found_sole_source_plan if found_sole_source_plan
          errors.add(:single_plan_hios_id, "hios id #{single_plan_hios_id.strip} not found for single plan benefit group")
        else
          errors.add(:single_plan_hios_id, "no hios id specified for single plan benefit group")
        end
      end
    end
  end
end
