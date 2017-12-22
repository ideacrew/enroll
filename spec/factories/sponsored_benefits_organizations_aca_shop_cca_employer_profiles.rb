FactoryGirl.define do
  factory :shop_cca_employer_profile, class: 'SponsoredBenefits::Organizations::AcaShopCcaEmployerProfile' do

    sic_code '0111'
    profile_source 'broker_quote'
    contact_method 'Only Electronic communications'

  end
end
