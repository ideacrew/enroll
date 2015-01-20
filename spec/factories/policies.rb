FactoryGirl.define do
  factory :policy do
    sequence(:eg_id) { |n| "#{n}" }
    pre_amt_tot '666.66'
    tot_res_amt '111.11'
    tot_emp_res_amt '222.22'
    carrier_to_bill true
    allocated_aptc '1.11'
    elected_aptc '2.22'
    applied_aptc '3.33'
    broker
    plan

    after(:create) do |p, evaluator|
      create_list(:enrollee, 2, policy: p)
    end
  end
end
