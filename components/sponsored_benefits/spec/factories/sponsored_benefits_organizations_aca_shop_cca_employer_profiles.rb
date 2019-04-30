FactoryGirl.define do
  factory :shop_cca_employer_profile, class: 'SponsoredBenefits::Organizations::AcaShopCcaEmployerProfile' do

    sic_code '0111'

    before(:create) do |profile, evaluator|
      profile.office_locations << FactoryGirl.build(:sponsored_benefits_office_location, :primary)
    end
  end
end
