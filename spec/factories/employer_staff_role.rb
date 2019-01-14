FactoryBot.define do
  factory :employer_staff_role do
    person
    is_owner true
#    employer_profile_id { create(:employer_profile).id }
#    benefit_sponsor_employer_profile_id { create(:benefit_sponsors_organizations_aca_shop_cca_employer_profile, :with_organization_and_site).id }

    before :create do |esr, evaluator|
      unless esr.employer_profile_id
        esr.employer_profile_id = create(:employer_profile).id
      end
      unless esr.benefit_sponsor_employer_profile_id
        esr.benefit_sponsor_employer_profile_id = create(:benefit_sponsors_organizations_aca_shop_cca_employer_profile, :with_organization_and_site).id
      end
    end
  end
end
