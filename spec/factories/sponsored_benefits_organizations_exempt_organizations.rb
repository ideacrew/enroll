FactoryGirl.define do
  factory :sponsored_benefits_organizations_exempt_organization, class: 'SponsoredBenefits::Organizations::ExemptOrganization' do
    legal_name "ACME Widgets, Inc."
    dba "ACME Widgets Co."
    entity_kind :s_corporation

    office_locations do
      [ build(:sponsored_benefits_office_location, :primary) ]
    end
    
    trait :with_site do
      before :build do |organization, evaluator|
        build(:sponsored_benefits_site, owner_organization: organization, site_organizations: [organization])
      end
    end


  end
end
