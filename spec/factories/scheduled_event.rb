FactoryGirl.define do
  factory :scheduled_event do
  	type 'holiday'
  	event_name 'Christmas'
  	start_date {Date.today}
  	one_time true
  	recurring_rules nil
  	offset_rule 'none'
  end
end