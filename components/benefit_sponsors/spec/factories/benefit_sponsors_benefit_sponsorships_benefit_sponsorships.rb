FactoryGirl.define do
  factory :benefit_sponsors_benefit_sponsorship, class: 'BenefitSponsors::BenefitSponsorships::BenefitSponsorship' do
    benefit_market { ::BenefitMarkets::BenefitMarket.new(kind: :aca_shop, title: "MA Health SHOP", site_urn: :cca) }
    profile_id { FactoryGirl.build(:benefit_sponsors_organizations_aca_shop_cca_employer_profile) }
    organization { FactoryGirl.build(:benefit_sponsors_organizations_general_organization, :with_site) }

    trait :with_benefit_market do
      # build only markey here
    end

    trait :with_organization_dc_profile do
      organization { FactoryGirl.build(:benefit_sponsors_organizations_general_organization) }
      profile { FactoryGirl.build(:benefit_sponsors_organizations_aca_shop_dc_employer_profile) }
    end

    trait :with_full_package do
      organization { FactoryGirl.build(:benefit_sponsors_organizations_general_organization, :with_site) }
      # using another engine
      benefit_market { ::BenefitMarkets::BenefitMarket.new(kind: :aca_shop, title: "MA Health SHOP", site_urn: :cca) }
      profile { FactoryGirl.build(:benefit_sponsors_organizations_aca_shop_cca_employer_profile) }
    end

    trait :with_market_profile do
      # we have to update the factory create instead of build
      before(:create) do |sponsorship, evaluator|
        sponsorship.organization = FactoryGirl.build(:benefit_sponsors_organizations_general_organization)
        sponsorship.benefit_market = ::BenefitMarkets::BenefitMarket.new(kind: :aca_shop, title: "DC Health SHOP", site_urn: :dc)
        sponsorship.profile = FactoryGirl.build(:benefit_sponsors_organizations_aca_shop_dc_employer_profile)
      end
    end
  end
end
