FactoryGirl.define do
  factory :benefit_sponsors_benefit_sponsorship, class: 'BenefitSponsors::BenefitSponsorships::BenefitSponsorship' do
    benefit_market 'aca_shop_cca'
    profile_id { BSON::ObjectId.from_time(DateTime.now) }
    organization 'rpsec_organization'

    trait :with_benefit_market do
      # build only markey here
    end

    trait :with_organization_dc_profile do
      # build organizationa and employer profile
    end

    trait :with_full_package do
      organization { FactoryGirl.build(:benefit_sponsors_organizations_general_organization) }
      # using another engine
      benefit_market { ::BenefitMarkets::BenefitMarket.new(kind: :aca_shop, title: "DC Health SHOP") }
      profile { FactoryGirl.build(:benefit_sponsors_organizations_aca_shop_dc_employer_profile) }
    end

   trait :with_market_profile do
     # we have to update the factory create instead of build
    before(:create) do |sponser_ship, evaluator|
      sponser_ship.organization = FactoryGirl.build(:benefit_sponsors_organizations_general_organization)
      sponser_ship.benefit_market = ::BenefitMarkets::BenefitMarket.new(kind: :aca_shop, title: "DC Health SHOP", site_urn: :dc)
      sponser_ship.profile = FactoryGirl.build(:benefit_sponsors_organizations_aca_shop_dc_employer_profile)
    end
  end





  end
end
