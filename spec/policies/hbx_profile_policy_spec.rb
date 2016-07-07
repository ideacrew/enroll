require "rails_helper"

describe HbxProfilePolicy do
  subject { described_class }
  let(:hbx_profile){ hbx_staff_person.hbx_staff_role.hbx_profile }
  let(:hbx_staff_person) { FactoryGirl.create(:person, :with_hbx_staff_role) }
  let(:assister_person) { FactoryGirl.create(:person, :with_assister_role) }
  let(:csr_person) { FactoryGirl.create(:person, :with_csr_role) }
  let(:employee_person) { FactoryGirl.create(:person, :with_employee_role)}

  permissions :show? do
    it "grants access when hbx_staff" do
      expect(subject).to permit(FactoryGirl.build(:user, :hbx_staff, person: hbx_staff_person), HbxProfile)
    end

    it "grants access when csr" do
      expect(subject).to permit(FactoryGirl.build(:user, :csr, person: csr_person), HbxProfile)
    end

    it "grants access when assister" do
      expect(subject).to permit(FactoryGirl.build(:user, :assister, person: assister_person), HbxProfile)
    end

    it "denies access when employee" do
      expect(subject).not_to permit(FactoryGirl.build(:user, :employee, person: employee_person), HbxProfile)
    end

    it "denies access when normal user" do
      expect(subject).not_to permit(User.new, HbxProfile)
    end
  end

  permissions :index? do
    it "grants access when hbx_staff" do
      expect(subject).to permit(FactoryGirl.build(:user, :hbx_staff, person: hbx_staff_person), HbxProfile)
    end

    it "denies access when csr" do
      expect(subject).not_to permit(FactoryGirl.build(:user, :csr, person: csr_person), HbxProfile)
    end

    it "denies access when normal user" do
      expect(subject).not_to permit(User.new, HbxProfile)
    end
  end

  permissions :edit? do
    it "denies access when csr" do
      expect(subject).not_to permit(FactoryGirl.build(:user, :csr, person: csr_person), HbxProfile)
    end

    it "denies access when normal user" do
      expect(subject).not_to permit(User.new, HbxProfile)
    end

    context "when hbx_staff" do
      let(:user) { FactoryGirl.create(:user, :hbx_staff, person: hbx_staff_person) }

      it "grants access" do
        expect(subject).to permit(user, hbx_profile)
      end

      it "denies access" do
        expect(subject).not_to permit(user, HbxProfile.new)
      end
    end
  end
end
