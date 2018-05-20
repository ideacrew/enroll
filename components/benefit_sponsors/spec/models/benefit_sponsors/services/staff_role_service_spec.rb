require 'rails_helper'

module BenefitSponsors
  RSpec.describe ::BenefitSponsors::Services::StaffRoleService, type: :model, :dbclean => :after_each do

    subject { BenefitSponsors::Services::StaffRoleService.new }

    let(:staff_class) { BenefitSponsors::Organizations::OrganizationForms::StaffRoleForm }
    let!(:site)  { FactoryGirl.create(:benefit_sponsors_site, :with_owner_exempt_organization, :dc) }
    let!(:benefit_sponsor) {FactoryGirl.create(:benefit_sponsors_organizations_general_organization, :with_aca_shop_dc_employer_profile, site: site)}
    let!(:employer_profile) {benefit_sponsor.employer_profile}
    let!(:active_employer_staff_role) {FactoryGirl.build(:benefit_sponsor_employer_staff_role, aasm_state:'is_active', benefit_sponsor_employer_profile_id: employer_profile.id)}
    let!(:person) { FactoryGirl.create(:person, employer_staff_roles:[active_employer_staff_role]) }
    let(:user) { FactoryGirl.create(:user, :person => person)}

    let(:staff_role_form) { BenefitSponsors::Organizations::OrganizationForms::StaffRoleForm.new(
        profile_id: employer_profile.id)
    }


    describe ".find_profile" do

      it 'should return employer profile' do
        expect(subject.find_profile(staff_role_form)).to eq employer_profile
      end
    end
  end
end
