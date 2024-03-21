require "rails_helper"

describe AccessPolicies::GeneralAgencyProfile, :dbclean => :after_each do
  subject { AccessPolicies::GeneralAgencyProfile.new(user) }
  let(:ga_controller) { GeneralAgencies::ProfilesController.new }

  context "authorize new" do
    let(:general_agency_staff_role) { FactoryBot.create(:general_agency_staff_role, aasm_state: 'active', is_primary: true) }
    let(:person) { general_agency_staff_role.person }
    let(:user) { FactoryBot.create(:user, :general_agency_staff, person: person) }

    it "should redirect" do
      expect(ga_controller).to receive(:redirect_to_show)
      subject.authorize_new(ga_controller)
    end
  end

  context "authorize index" do
    context "for an admin user" do
      let(:user) { FactoryBot.create(:user, person: person) }
      let(:person) { FactoryBot.create(:person, :with_hbx_staff_role) }

      it "should authorize" do
        expect(subject.authorize_index(ga_controller)).to be_truthy
      end
    end

    context "for a broker_role" do
      let(:person) { FactoryBot.create(:person) }
      let(:user) { FactoryBot.create(:user, :broker, person: person) }

      it "should authorize" do
        expect(subject.authorize_index(ga_controller)).to be_truthy
      end
    end

    context "for csr user" do
      let(:person) { FactoryBot.create(:person) }
      let(:user) { FactoryBot.create(:user, :csr, person: person) }

      it "should authorize" do
        expect(subject.authorize_index(ga_controller)).to be_truthy
      end
    end

    context "for normal user" do
      let(:user) { FactoryBot.create(:user) }

      it "should be redirect" do
        expect(ga_controller).to receive(:redirect_to_new)
        subject.authorize_index(ga_controller)
      end
    end

    context "for normal user with general_agency_profile" do
      let(:general_agency_staff_role) { FactoryBot.create(:general_agency_staff_role, aasm_state: 'active', is_primary: true) }
      let(:person) { general_agency_staff_role.person }
      let(:user) { FactoryBot.create(:user, :general_agency_staff, person: person) }

      it "should redirect" do
        expect(ga_controller).to receive(:redirect_to_show)
        subject.authorize_new(ga_controller)
      end
    end
  end
end

describe AccessPolicies::GeneralAgencyProfile, "checking for ability to view families" do

  let(:general_agency_profile_id) { "SOME BOGUS ID" }
  let(:hbx_staff_user) { instance_double(User, has_hbx_staff_role?: true)}
  let(:general_agency_staff_user) { instance_double(User, has_hbx_staff_role?: false, person: general_agency_staff_person) }
  let(:normal_user) { instance_double(User, has_hbx_staff_role?: false, person: normal_person) }
  let(:general_agency) { instance_double(GeneralAgencyProfile, id: general_agency_profile_id) }
  let(:general_agency_staff_role) do
    instance_double(
      GeneralAgencyStaffRole,
      {
        general_agency_profile_id: general_agency_profile_id,
        active?: true
      }
    )
  end
  let(:normal_person) do
    instance_double(
      Person,
      general_agency_staff_roles: []
    )
  end
  let(:general_agency_staff_person) do
    instance_double(
      Person,
      general_agency_staff_roles: [general_agency_staff_role]
    )
  end

  it "allows an hbx-staff user" do
    authorized = AccessPolicies::GeneralAgencyProfile.new(hbx_staff_user).view_families(general_agency)
    expect(authorized).to be_truthy
  end

  it "allows a user who is active general agency staff" do
    authorized = AccessPolicies::GeneralAgencyProfile.new(general_agency_staff_user).view_families(general_agency)
    expect(authorized).to be_truthy
  end

  it "denies a regular user" do
    authorized = AccessPolicies::GeneralAgencyProfile.new(normal_user).view_families(general_agency)
    expect(authorized).to be_falsey
  end
end
