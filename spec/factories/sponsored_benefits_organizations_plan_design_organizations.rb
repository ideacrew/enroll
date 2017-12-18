FactoryGirl.define do
  factory :sponsored_benefits_organizations_plan_design_organization, class: 'SponsoredBenefits::Organizations::PlanDesignOrganization' do
    legal_name  "Turner Agency, Inc"
    dba         "Turner Brokers"

    fein do
      Forgery('basic').text(:allow_lower   => false,
        :allow_upper   => false,
        :allow_numeric => true,
        :allow_special => false, :exactly => 9)
    end
  end
end
