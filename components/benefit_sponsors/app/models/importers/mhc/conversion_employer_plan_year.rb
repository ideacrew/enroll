module Importers::Mhc
  class ConversionEmployerPlanYear < Importers::ConversionEmployerPlanYear

    CARRIER_MAPPING = {
        "bmc healthnet plan"=>"BMCHP",
        "fallon community health plan"=>"FCHP",
        "health new england"=>"HNE",
        "neighborhood health plan" => "NHP",
        "harvard pilgrim health care" => "HPHC",
        "boston medical center health plan" => "BMCHP",
        "blue cross blue shield ma" => "BCBS",
        "tufts health plan premier" => "THPP",
        "tufts health direct" => "THPD"
    }

    validate :validate_plan_selection, :validate_reference_plan

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

    def initialize(opts = {})
      super(opts)
    end

    def plan_selection=(val)
      @plan_selection = val.to_s.parameterize('_')
    end

    def find_carrier
      carrier = BenefitSponsors::Organizations::IssuerProfile.find_by_issuer_name("Fallon Health")
      # return nil unless carrier
    end

    def validate_reference_plan
      found_carrier = find_carrier
      if found_carrier.blank?
        errors.add(:carrer, "carrier not found")
        return
      end

      # available_plans = Plan.valid_shop_health_plans("carrier", found_carrier.id, (calculated_coverage_start).year).compact
      # select_reference_plan(available_plans, (calculated_coverage_start).year)
    end

    def validate_plan_selection
      if plan_selection != 'sole_source'
        errors.add(:plan_selection, "invalid plan selection specified (not sole source)")
      end
    end
  end
end
