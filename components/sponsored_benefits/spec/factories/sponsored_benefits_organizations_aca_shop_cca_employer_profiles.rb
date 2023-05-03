FactoryBot.define do
  factory :shop_cca_employer_profile, class: 'SponsoredBenefits::Organizations::AcaShopCcaEmployerProfile' do

    sic_code { '0111' }
    benefit_sponsorships {[FactoryBot.build(:plan_design_benefit_sponsorship)]}

    before(:create) do |profile, evaluator|
      profile.office_locations << FactoryBot.build(:sponsored_benefits_office_location, :primary)
    end
  end
end
