module Importers::Mhc
  class ConversionEmployerPlanYear < Importers::ConversionEmployerPlanYear

    CARRIER_MAPPING = {
      "bmc healthnet plan"=>"BMCHP", 
      "fallon health"=>"FCHP", 
      "health new england"=>"HNE"
    }

    attr_accessor :employee_only_rt,
      :employee_only_rt_contribution,
      :employee_only_rt_cost,
      :family_rt,
      :family_rt_contribution,
      :family_rt_cost

    def plan_selection=(val)
      @plan_selection = val.to_s.parameterize('_')
    end
  end
end
