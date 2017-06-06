FactoryGirl.define do
  factory :scheduled_event do
  	type 'holiday'
  	event_name 'Christmas'
    start_time { Date.new(2017, 1, 1) }
    one_time true
    offset_rule 3

	  trait :empty_recurring_rules do
	    recurring_rules nil
	  end

	  trait :recurring_rules do
	   recurring_rules { }  
	  end

	  trait :offset_0 do
	    offset_rule 0
	  end

	  trait :offset_1 do
	    offset_rule 1
	  end

	  trait :offset_2 do
	    offset_rule 2
	  end

	  trait :offset_3 do
	    offset_rule 3
	  end

	  trait :offset_4 do
	    offset_rule 4
	  end

	  trait :start_on_friday do
	    start_time { Date.today.sunday + 5.day }
	  end

	  trait :start_on_saturday do
	    start_time { Date.today.sunday + 6.day }
	  end

	  trait :start_on_sunday do
	    start_time { Date.today.sunday }
	  end
	end
end