FactoryGirl.define do
  factory :benefit_sponsors_organizations_general_organization, class: 'BenefitSponsors::Organizations::GeneralOrganization' do
    legal_name  "ACME Widgets, Inc."
    dba         "ACME Co."
    entity_kind :c_corporation

    fein do
      Forgery('basic').text(:allow_lower   => false,
        :allow_upper   => false,
        :allow_numeric => true,
        :allow_special => false, :exactly => 9)
    end

    trait :with_broker_agency_profile do
      after :build do |organization, evaluator|
        build(:benefit_sponsors_organizations_broker_agency_profile, organization: organization)
      end
    end

    trait :with_site do
      after :build do |organization, evaluator|
      end
    end
  end
end
