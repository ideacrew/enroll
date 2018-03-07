FactoryGirl.define do
  factory :sponsored_benefits_organizations_general_organization, class: 'SponsoredBenefits::Organizations::GeneralOrganization' do
    legal_name "ACME Widgets, Inc."
    dba "ACME Widgets Co."
    entity_kind :s_corporation

    site do
      build(:sponsored_benefits_site)
    end

    fein do
      Forgery('basic').text(:allow_lower   => false,
        :allow_upper   => false,
        :allow_numeric => true,
        :allow_special => false, :exactly => 9)
    end

    office_locations do
      [ build(:sponsored_benefits_office_location, :primary) ]
    end
    
    trait :with_aca_shop_dc_employer_profile do
      after :build do |organization, evaluator|
        organization.profiles << build(:sponsored_benefits_organizations_aca_shop_dc_employer_profile)
      end
    end



  end
end
