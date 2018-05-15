FactoryGirl.define do
  factory :benefit_sponsors_organizations_exempt_organization, class: 'BenefitSponsors::Organizations::ExemptOrganization' do
    legal_name "ACME Widgets, Inc."
    dba "ACME Widgets Co."
    entity_kind :s_corporation

    # office_locations do
    #   [ build(:benefit_sponsors_locations_office_location, :primary) ]
    # end

    # association :profiles, factory: :benefit_sponsors_organizations_hbx_profile
    # profiles { [ build(:benefit_sponsors_organizations_aca_shop_dc_employer_profile) ] }
    profiles { [ build(:benefit_sponsors_organizations_hbx_profile) ] }

    trait :with_site do
      before :build do |organization, evaluator|
        build(:benefit_sponsors_site, owner_organization: organization, site_organizations: [organization])
      end
    end

    trait :with_hbx_profile do
      after :build do |organization, evaluator|
        build(:benefit_sponsors_organizations_hbx_profile)
      end
    end
    
    trait :with_hbx_profile do
      after :build do |organization, evaluator|
        organization.profiles << build(:benefit_sponsors_organizations_hbx_profile)
      end
    end

  end


# factory :benefit_sponsors_organizations_exempt_organization_with_profiles, parent: :benefit_sponsors_organizations_exempt_organization do |profile|
#   profiles { build_profile :benefit_sponsors_organizations_hbx_profile, 1 }
# end


end
