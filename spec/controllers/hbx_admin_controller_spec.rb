require 'rails_helper'

RSpec.describe HbxAdminController, :type => :controller do
  let(:user) { FactoryBot.create(:user) }
  let(:person_with_family) { FactoryBot.create(:person, :with_family) }
  let(:family) { person_with_family.primary_family }
  let(:person_with_fam_hbx_enrollment) { person_with_family.primary_family.active_household.hbx_enrollments.build }
  let(:tax_household) { family.active_household.tax_households.build }
  let(:eligibility_determination) { family.active_household.tax_households.first.eligibility_determinations.build(source: 'Admin') }
  let(:organization) do
    FactoryBot.create(:organization, hbx_profile: FactoryBot.create(:hbx_profile))
  end
  let(:valid_benefit_sponsorship)  { FactoryBot.create(:benefit_sponsors_benefit_sponsorship, :with_full_package) }
  let(:valid_date)  { TimeKeeper.date_of_record.beginning_of_month }
  let(:hbx_staff_permission) do
    instance_double(
      Permission,
      :can_edit_aptc => true
    )
  end
  let(:hbx_staff_role) do
    instance_double(
      HbxStaffRole,
      :permission => hbx_staff_permission
    )
  end
  let(:user_person) do
    instance_double(
      Person,
      :hbx_staff_role => hbx_staff_role
    )
  end

  before :each do
    allow(user).to receive(:has_hbx_staff_role?).and_return(true)
    allow(user).to receive(:person).and_return(user_person)
    sign_in(user)
    allow(EnrollRegistry[:apply_aggregate_to_enrollment].feature).to receive(:is_enabled).and_return(false)
  end

  describe "GET calculate_aptc_csr" do
    before do
      allow(HbxProfile).to receive(:current_hbx).and_return(organization)
      allow(Admin::Aptc).to receive(:calculate_slcsp_value).with(valid_date.year, family).and_return('100')
      allow(Admin::Aptc).to receive(:years_with_tax_household).with(family).and_return(valid_date.year)
    end

    it "should initialize the variables for the method and render the proper template" do
      get(:calculate_aptc_csr, params: { person_id: person_with_family.id, family_id: family.id, year: valid_date.year, max_aptc: 100 }, format: :js)
    end
  end
end
