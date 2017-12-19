FactoryGirl.define do
  factory :plan_design_organization, class: 'SponsoredBenefits::Organizations::PlanDesignOrganization' do
    legal_name  "Turner Agency, Inc"
    dba         "Turner Brokers"

    fein do
      Forgery('basic').text(:allow_lower   => false,
        :allow_upper   => false,
        :allow_numeric => true,
        :allow_special => false, :exactly => 9)
    end

    office_locations do
      [ build(:sponsored_benefits_office_location, :primary) ]
    end
  end
end
