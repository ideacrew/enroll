FactoryGirl.define do
  factory :benefit_sponsors_organizations_aca_shop_cca_employer_profile, class: 'BenefitSponsors::Organizations::AcaShopCcaEmployerProfile' do

    # employer_attestation  { BenefitSponsors::Documents::EmployerAttestation.new(aasm_state: "approved") }
    sic_code              "001"
    referred_by           "Other"
    referred_reason       "Other Reason"

    transient do
      site nil
      secondary_office_locations_count 1
    end

    after(:build) do |profile, evaluator|
      profile.office_locations = [build(:benefit_sponsors_locations_office_location, :with_massachusetts_address)]
    end
  end
end
