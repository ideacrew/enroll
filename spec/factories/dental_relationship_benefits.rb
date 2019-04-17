FactoryBot.define do
  factory :dental_relationship_benefit do
    relationship     { :employee }
    premium_pct             { 40 }
    employer_max_amt       { 100 }
    offered               { true }
  end
end
