FactoryGirl.define do
  factory :sponsored_benefits_site, class: 'SponsoredBenefits::Site' do
    site_key    :acme
    long_name   "ACME Widget's Benefit Website"
    short_name  "Benefit Website"
    domain_name "hbxshop.org"

    transient do
      legal_name "My Exchange Site"
      fein "012345678"
      kind :aca_shop
    end

    trait :with_owner_general_organization do
      after :build do |site, evaluator|
        build(:sponsored_benefits_organizations_general_organization, site_owner: site, site: site, legal_name: evaluator.legal_name, fein: evaluator.fein)
      end
    end

    trait :with_owner_exempt_organization do
      after :build do |site, evaluator|
        build(:sponsored_benefits_organizations_exempt_organization, site_owner: site, site: site, legal_name: evaluator.legal_name)
      end
    end

    trait :with_benefit_market do
      after :build do |site, evaluator|
        site.benefit_markets << build(:sponsored_benefits_benefit_markets_benefit_market, kind: evaluator.kind)
      end
    end
    
  end
end
