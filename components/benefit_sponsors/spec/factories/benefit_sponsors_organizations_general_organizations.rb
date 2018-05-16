FactoryGirl.define do
  factory :benefit_sponsors_organizations_general_organization, class: 'BenefitSponsors::Organizations::GeneralOrganization' do
    legal_name "ACME Widgets, Inc."
    dba "ACME Widgets Co."
    entity_kind :c_corporation

    fein do
      Forgery('basic').text(:allow_lower   => false,
        :allow_upper   => false,
        :allow_numeric => true,
        :allow_special => false, :exactly => 9)
    end

    # office_locations do
    #   [ build(:benefit_sponsors_locations_office_location, :primary) ]
    # end

    # association :profiles, factory: :benefit_sponsors_organizations_aca_shop_dc_employer_profile
    # profiles { [ build(:benefit_sponsors_organizations_aca_shop_dc_employer_profile) ] }

    trait :with_site do
      after :build do |organization, evaluator|
        build(:benefit_sponsors_site, owner_organization: organization, site_organizations: [organization])
      end
    end

    trait :with_aca_shop_dc_employer_profile do
      after :build do |organization, evaluator|
        profile = build(:benefit_sponsors_organizations_aca_shop_dc_employer_profile)
        organization.profiles = [profile]
        organization.benefit_sponsorships = [build(:benefit_sponsors_benefit_sponsorship,
          :with_benefit_market,
          profile: profile
        )]
      end
    end

    trait :with_aca_shop_cca_employer_profile do
      after :build do |organization, evaluator|
        profile = build(:benefit_sponsors_organizations_aca_shop_cca_employer_profile)
        organization.profiles = [profile]
        organization.benefit_sponsorships = [build(:benefit_sponsors_benefit_sponsorship,
          :with_benefit_market, 
          profile: profile
        )]
      end
    end

    trait :with_aca_shop_dc_employer_profile_initial_application do
      with_aca_shop_dc_employer_profile
      after :build do |organization, evaluator|
        organization.benefit_sponsorships = [build(:benefit_sponsors_benefit_sponsorship,
          :with_benefit_market,
          :with_initial_benefit_application,
          profile: organization.employer_profile
        )]
      end
    end

    trait :with_aca_shop_cca_employer_profile_initial_application do
      with_aca_shop_cca_employer_profile
      after :build do |organization, evaluator|
        organization.benefit_sponsorships = [build(:benefit_sponsors_benefit_sponsorship,
          :with_benefit_market,
          :with_initial_benefit_application,
          profile: organization.employer_profile
        )]
      end
    end

    trait :with_aca_shop_dc_employer_profile_renewal_application do
      with_aca_shop_dc_employer_profile
      after :build do |organization, evaluator|
        organization.benefit_sponsorships = [build(:benefit_sponsors_benefit_sponsorship,
          :with_benefit_market,
          :with_renewal_benefit_application,
          profile: organization.employer_profile
        )]
      end
    end

    trait :with_aca_shop_cca_employer_profile_renewal_application do
      with_aca_shop_cca_employer_profile
      after :build do |organization, evaluator|
        organization.benefit_sponsorships = [build(:benefit_sponsors_benefit_sponsorship,
          :with_benefit_market,
          :with_renewal_benefit_application,
          profile: organization.employer_profile
        )]
      end
    end

    trait :with_aca_shop_cca_employer_profile_expired_application do
      with_aca_shop_cca_employer_profile
      after :build do |organization, evaluator|
        organization.benefit_sponsorships = [build(:benefit_sponsors_benefit_sponsorship,
          :with_benefit_market,
          :with_expired_and_active_benefit_application,
          profile: organization.employer_profile
        )]
      end
    end

    trait :with_broker_agency_profile do
      after :build do |organization, evaluator|
        organization.profiles << build(:benefit_sponsors_organizations_broker_agency_profile)
      end
    end

    trait :with_hbx_profile do
      after :build do |organization, evaluator|
        organization.profiles << build(:benefit_sponsors_organizations_hbx_profile)
      end
    end
  end
end
