require "pundit/rspec"
require "rails_helper"

describe ConsumerRolePolicy do
  subject { described_class }
  let(:consumer_role){ FactoryGirl.create(:consumer_role)}

  permissions :privacy? do
    it "grants access when consumer" do
      expect(subject).to permit(FactoryGirl.build(:user, :consumer), ConsumerRole)
    end

    it "grants access when broker" do
      expect(subject).to permit(FactoryGirl.build(:user, :broker), ConsumerRole)
    end

    it "grants access when assister" do
      expect(subject).to permit(FactoryGirl.build(:user, :assister), ConsumerRole)
    end

    it "grants access when csr" do
      expect(subject).to permit(FactoryGirl.build(:user, :csr), ConsumerRole)
    end

    it "grants access when user without roles" do
      expect(subject).to permit(User.new, ConsumerRole)
    end

    it "denies access when employee" do
      expect(subject).not_to permit(FactoryGirl.build(:user, :employee), ConsumerRole)
    end

    it "denies access when employer_staff" do
      expect(subject).not_to permit(FactoryGirl.build(:user, :employer_staff), ConsumerRole)
    end
  end

  permissions :edit? do
    let(:user) {FactoryGirl.create(:user, :consumer)}
    let(:person) {FactoryGirl.build(:person)}
    it "grants access when hbx_staff" do
      expect(subject).to permit(FactoryGirl.build(:user, :hbx_staff), consumer_role)
    end

    it "denies access when normal user" do
      expect(subject).not_to permit(User.new, consumer_role)
    end

    context "consumer" do
      before :each do
        allow(user).to receive(:person).and_return person
      end

      it "grants access" do
        allow(person).to receive(:consumer_role).and_return consumer_role
        expect(subject).to permit(user, consumer_role)
      end

      it "denies access" do
        allow(person).to receive(:consumer_role).and_return ConsumerRole.new
        expect(subject).not_to permit(user, consumer_role)
      end
    end
  end
end
