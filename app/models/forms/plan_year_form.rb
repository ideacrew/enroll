module Forms
  class PlanYearForm < SimpleDelegator
     def initialize(py)
       super(py)
       @all_plans = Plan.where(active_year: Time.now.year, market: "shop").to_a
     end

     [:start_on, :end_on, :open_enrollment_end_on, :open_enrollment_start_on].each do |attr|
       class_eval(<<-RUBYCODE)
         def #{attr}
           __getobj__.#{attr}.blank? ? nil : __getobj__.#{attr}.strftime("%m/%d/%Y")
         end

         def #{attr}=(val)
           __getobj__.#{attr} = Date.strptime(val, "%m/%d/%Y") rescue nil
         end
       RUBYCODE
     end

     def carrier_plans_for(c_profile)
       @all_plans.select { |pl| pl.carrier_profile_id.to_s == c_profile.id.to_s }
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
