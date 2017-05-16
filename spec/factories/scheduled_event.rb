FactoryGirl.define do
  factory :scheduled_event do
  	type 'holiday'
  	event_name 'Christmas'
<<<<<<< HEAD
  	start_time { Date.new(2017, 1, 1) }
=======
  	start_time {Date.today}
>>>>>>> specs and fixes
  	one_time true
  	recurring_rules nil
  	offset_rule '3'
  	trait :recurring_rule do
      recurring_rules {"validations"=>{"day_of_month"=>[27]}, "rule_type"=>"IceCube::MonthlyRule", "interval"=>1}
    end
  end
end