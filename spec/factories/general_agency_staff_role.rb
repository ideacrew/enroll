FactoryBot.define do
  factory :general_agency_staff_role, class: '::GeneralAgencyStaffRole' do
    person { FactoryBot.create(:person) }
    npn do
      Forgery('basic').text(:allow_lower   => false,
                            :allow_upper   => false,
                            :allow_numeric => true,
                            :allow_special => false, :exactly => 8)
    end

    before :create do |esr, evaluator|
      unless esr.general_agency_profile_id
        esr.general_agency_profile_id = create(:general_agency_profile).id
      end
      unless esr.benefit_sponsors_general_agency_profile_id
        esr.benefit_sponsors_general_agency_profile_id = create(:benefit_sponsors_organizations_aca_shop_cca_employer_profile, :with_organization_and_site).id
      end
    end
  end
end
