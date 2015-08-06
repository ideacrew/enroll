module Forms
  class PlanYearForm < SimpleDelegator
     def initialize(py)
       super(py)
     end

     def carrier_plans_for(c_profile_id)
       Rails.cache.fetch("plans-for-carrier-#{c_profile_id.to_s}-at-#{::TimeKeeper.date_of_record.year}", expires_in: 2.hour) do
         ::Plan.valid_shop_health_plans("carrier", c_profile_id).map{|plan| ["#{::Organization.valid_carrier_names[plan.carrier_profile_id.to_s]} - #{plan.name}", plan.id.to_s]}
       end
     end

     def metal_level_plans_for(metal_level)
       Rails.cache.fetch("plans-for-metal-level-#{metal_level}-at-#{::TimeKeeper.date_of_record.year}", expires_in: 2.hour) do
         ::Plan.valid_shop_health_plans("metal_level", metal_level).map{|plan| ["#{::Organization.valid_carrier_names[plan.carrier_profile_id.to_s]} - #{plan.name}", plan.id.to_s]}
       end
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

     def self.rebuild(plan_year, atts)
       self.new(plan_year).tap do |proxy|
         proxy.assign_plan_year_attributes(atts)
       end
     end
  end
end
