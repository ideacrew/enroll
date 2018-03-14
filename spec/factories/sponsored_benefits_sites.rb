FactoryGirl.define do
  factory :sponsored_benefits_site, class: 'SponsoredBenefits::Site' do
    site_key    :acme
    long_name   "ACME Widget's Benefit Website"
    short_name  "Benefit Website"
    domain_name "hbxshop.org"

    trait :with_owner_general_organization do
      association :owner_organization, factory: :sponsored_benefits_organizations_general_organization
      
      after :build do |site, evaluator|
        site.site_organizations << site.owner_organization
      end
    end

    trait :with_owner_exempt_organization do
      association :owner_organization, factory: :sponsored_benefits_organizations_exempt_organization
      
      after :build do |site, evaluator|
        site.site_organizations << site.owner_organization
      end
    end

    trait :with_benefit_market do
      after :build do |site, evaluator|
        site.benefit_markets << build(:sponsored_benefits_benefit_markets_benefit_market, kind: evaluator.kind)
      end
    end

  end
end
