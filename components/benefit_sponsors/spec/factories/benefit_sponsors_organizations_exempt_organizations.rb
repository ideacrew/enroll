FactoryGirl.define do
  factory :benefit_sponsors_organizations_exempt_organization, class: 'BenefitSponsors::Organizations::ExemptOrganization' do
    legal_name "Health Agency Authority"
    dba "Health Insurance Depot"
    entity_kind :health_insurance_exchange
    site        { create(:benefit_sponsors_site, :with_owner_exempt_organization) }

    # office_locations do
    #   [ build(:benefit_sponsors_locations_office_location, :primary) ]
    # end

    # association :profiles, factory: :benefit_sponsors_organizations_hbx_profile
    # profiles { [ build(:benefit_sponsors_organizations_aca_shop_dc_employer_profile) ] }
    profiles { [ build(:benefit_sponsors_organizations_hbx_profile) ] }

    trait :with_site do
      after :build do |organization, evaluator|
        new_site = create(:benefit_sponsors_site, :with_owner_exempt_organization)
        organization.site = new_site
      end
    end

    trait :as_site do
      before :build do |organization, evaluator|
        build(:benefit_sponsors_site, owner_organization: organization, site_organizations: [organization])
      end
    end
  end


# factory :benefit_sponsors_organizations_exempt_organization_with_profiles, parent: :benefit_sponsors_organizations_exempt_organization do |profile|
#   profiles { build_profile :benefit_sponsors_organizations_hbx_profile, 1 }
# end


end
