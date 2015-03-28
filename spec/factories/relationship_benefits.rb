FactoryGirl.define do
  factory :relation_benefit do
    relationship     :employee
    premium_pct             40
    employer_max_amt       100
  end
end
