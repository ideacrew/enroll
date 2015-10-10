require "pundit/rspec"
require "rails_helper"

describe HbxProfilePolicy do
  subject { described_class }
  let(:hbx_profile){ FactoryGirl.create(:hbx_profile)}

  permissions :show? do
    it "grants access when hbx_staff" do
      expect(subject).to permit(FactoryGirl.build(:user, :hbx_staff), HbxProfile)
    end

    it "grants access when csr" do
      expect(subject).to permit(FactoryGirl.build(:user, :csr), HbxProfile)
    end

    it "grants access when assister" do
      expect(subject).to permit(FactoryGirl.build(:user, :assister), HbxProfile)
    end

    it "denies access when employee" do
      expect(subject).not_to permit(FactoryGirl.build(:user, :employee), HbxProfile)
    end

    it "denies access when normal user" do
      expect(subject).not_to permit(User.new, HbxProfile)
    end
  end

  permissions :index? do
    it "grants access when hbx_staff" do
      expect(subject).to permit(FactoryGirl.build(:user, :hbx_staff), HbxProfile)
    end

    it "denies access when csr" do
      expect(subject).not_to permit(FactoryGirl.build(:user, :csr), HbxProfile)
    end

    it "denies access when normal user" do
      expect(subject).not_to permit(User.new, HbxProfile)
    end
  end

  permissions :edit? do
    it "denies access when csr" do
      expect(subject).not_to permit(FactoryGirl.build(:user, :csr), HbxProfile)
    end

    it "denies access when normal user" do
      expect(subject).not_to permit(User.new, HbxProfile)
    end

    context "when hbx_staff" do
      let(:user) {FactoryGirl.create(:user, :hbx_staff)}
      let(:person) {FactoryGirl.build(:person)}
      let(:hbx_staff_role) {double}
      before :each do
        allow(user).to receive(:person).and_return person
        allow(person).to receive(:hbx_staff_role).and_return hbx_staff_role
      end

      it "grants access" do
        allow(hbx_staff_role).to receive(:hbx_profile).and_return hbx_profile
        expect(subject).to permit(user, hbx_profile)
      end

      it "denies access" do
        allow(hbx_staff_role).to receive(:hbx_profile).and_return HbxProfile.new
        expect(subject).not_to permit(user, hbx_profile)
      end
    end
  end
end
