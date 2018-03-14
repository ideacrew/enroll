FactoryGirl.define do
  factory :sponsored_benefits_organizations_general_organization, class: 'SponsoredBenefits::Organizations::GeneralOrganization' do
    legal_name "ACME Widgets, Inc."
    dba "ACME Widgets Co."
    entity_kind :s_corporation

    fein do
      Forgery('basic').text(:allow_lower   => false,
        :allow_upper   => false,
        :allow_numeric => true,
        :allow_special => false, :exactly => 9)
    end

    office_locations do
      [ build(:sponsored_benefits_office_location, :primary) ]
    end

    # association :profiles, factory: :sponsored_benefits_organizations_aca_shop_dc_employer_profile
    profiles { [ build(:sponsored_benefits_organizations_aca_shop_dc_employer_profile) ] }

    trait :with_site do
      before :build do |organization, evaluator|
        build(:sponsored_benefits_site, owner_organization: organization, site_organizations: [organization])
      end
    end
  
    trait :with_aca_shop_dc_employer_profile do
      before :build do |organization, evaluator|
        organization.profiles.build(:sponsored_benefits_organizations_aca_shop_dc_employer_profile)
      end
    end

  end
end
