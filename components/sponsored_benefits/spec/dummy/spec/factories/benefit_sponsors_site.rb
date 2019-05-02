FactoryBot.define do
  factory :benefit_sponsors_site, class: 'BenefitSponsors::Site' do
    byline      "ACME Healthcare"
    long_name   "ACME Widget's Benefit Website"
    short_name  "Benefit Website"
    domain_name "hbxshop.org"

    transient do
      kind :aca_shop
      site_owner_organization_legal_name "Site Owner"
    end

    trait :as_hbx_profile do
      # after :build do |site, evaluator|
      #   site.owner_organization = build(:benefit_sponsors_organizations_exempt_organization, :with_hbx_profile, site: site)
      # end
    end

    trait :cca do
      site_key :cca
    end
  end
end
