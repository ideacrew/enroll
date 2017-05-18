FactoryGirl.define do
  factory :scheduled_event do
  	type 'holiday'
  	event_name 'Christmas'
  	start_time { Date.new(2017, 1, 1) }
  	one_time true
  	recurring_rules nil
  	offset_rule '3'
  end
end