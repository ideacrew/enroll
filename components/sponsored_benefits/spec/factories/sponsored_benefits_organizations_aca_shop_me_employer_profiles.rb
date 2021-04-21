# frozen_string_literal: true

FactoryBot.define do
  factory :shop_me_employer_profile, class: 'SponsoredBenefits::Organizations::AcaShopMeEmployerProfile' do

    sic_code { '0111' } if ::EnrollRegistry.feature_enabled?(:sic_codes)

    before(:create) do |profile, _evaluator|
      profile.office_locations << FactoryBot.build(:sponsored_benefits_office_location, :primary)
    end
  end
end
