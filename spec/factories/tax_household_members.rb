FactoryBot.define do
  factory :tax_household_member do
    tax_household
    is_ia_eligible { true }
  end
end
