require 'rails_helper'

RSpec.describe HbxAdminController, :type => :controller do
  let(:user) { FactoryBot.create(:user) }
  let(:person_with_family) { FactoryBot.create(:person, :with_family) }
  let(:family) { person_with_family.primary_family }
  let(:person_with_fam_hbx_enrollment) { person_with_family.primary_family.active_household.hbx_enrollments.build }
  let(:organization) do
    FactoryBot.create(:organization, hbx_profile: FactoryBot.create(:hbx_profile))
  end
  let(:valid_benefit_sponsorship)  { FactoryBot.create(:benefit_sponsors_benefit_sponsorship, :with_full_package) }


  before :each do
    allow(user).to receive(:has_hbx_staff_role?).and_return(true)
    allow(HbxProfile).to receive(:current_hbx).and_return(organization)
    allow(Admin::Aptc).to receive(:calculate_slcsp_value).with(2019, family).and_return('100')
    allow(Admin::Aptc).to receive(:years_with_tax_household).with(family).and_return(2019)
    sign_in(user)
  end

  describe "POST edit_aptc_csr" do
    it "should initialize the variables for the method" do
      post(:edit_aptc_csr, params: { person_id: person_with_family.id, family_id: family.id, year: 2019}, format: :js)
      expect(subject).to render_template("hbx_admin/edit_aptc_csr_no_enrollment")
    end
  end
end