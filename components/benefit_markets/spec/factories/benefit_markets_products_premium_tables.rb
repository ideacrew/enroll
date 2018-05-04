FactoryGirl.define do
  factory :benefit_markets_products_premium_table, class: 'BenefitMarkets::Products::PremiumTable' do
    
    effective_period    Date.new(Date.today.year, 1, 1)..Date.new(Date.today.year, 3, 31)
    rating_area         BenefitMarkets::Locations::RatingArea.new

    after(:build) do |premium_table, evaluator|
      premium_table.premium_tuples << build_list(:benefit_markets_products_premium_tuple, 3)
    end

  end
end
