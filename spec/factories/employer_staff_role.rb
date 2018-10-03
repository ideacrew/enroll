FactoryGirl.define do
  factory :employer_staff_role do
    person
    is_owner true
    employer_profile_id { create(:employer_profile).id }
    benefit_sponsor_employer_profile_id { create(:benefit_sponsors_organizations_general_organization, :with_aca_shop_cca_employer_profile, :with_site).employer_profile.id }
  end

end
