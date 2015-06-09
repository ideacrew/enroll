FactoryGirl.define do
  factory :premium_statement do
    employer_profile  { FactoryGirl.build(:employer_profile) }
    effective_on  Date.current
    
  end

end
