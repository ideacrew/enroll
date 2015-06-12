module Forms
  class PlanYearForm < SimpleDelegator
     def initialize(py)
       super(py)
       @all_plans = Plan.where(active_year: Time.now.year, market: "shop", coverage_kind: "health").to_a
     end

     def carrier_plans_for(c_profile_id)
       @all_plans.select { |pl| pl.carrier_profile_id.to_s == c_profile_id.to_s }
     end

     def metal_level_plans_for(metal_level)
       @all_plans.select { |pl| pl.metal_level == metal_level }
     end

     def self.model_name
       ::PlanYear.model_name
     end

     def assign_plan_year_attributes(atts = {})
       atts.each_pair do |k, v|
         self.send("#{k}=".to_sym, v)
       end
     end

     def self.build(employer_profile, atts)
       new_py = employer_profile.plan_years.new
       self.new(new_py).tap do |new_proxy|
         new_proxy.assign_plan_year_attributes(atts)
       end
     end
  end
end
