FactoryGirl.define do
  factory :sponsored_benefits_benefit_sponsorships_plan_design_employer_profile, class: 'SponsoredBenefits::BenefitSponsorships::PlanDesignEmployerProfile' do
    plan_design_organization            { FactoryGirl.build(:sponsored_benefits_organizations_plan_design_organization) }

    entity_kind "MyString"
    sic_code "MyString"
    legal_name "MyString"
    dba "MyString"
  end
end
