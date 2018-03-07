FactoryGirl.define do
  factory :sponsored_benefits_organizations_exempt_organization, class: 'SponsoredBenefits::Organizations::ExemptOrganization' do
    legal_name "ACME Widgets, Inc."
    dba "ACME Widgets Co."
    entity_kind :s_corporation

    # site do
    #   build(:sponsored_benefits_site)
    # end

    office_locations do
      [ build(:sponsored_benefits_office_location, :primary) ]
    end
    
  end
end
