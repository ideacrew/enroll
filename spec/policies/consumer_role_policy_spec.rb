require "rails_helper"

if ExchangeTestingConfigurationHelper.individual_market_is_enabled?
describe ConsumerRolePolicy, dbclean: :after_each do
  subject { described_class }
  let(:consumer_role) { FactoryBot.create(:consumer_role) }
  let(:consumer_person) { FactoryBot.create(:person, :with_consumer_role) }
  let(:broker_person) { FactoryBot.create(:person, :with_broker_role) }
  let(:assister_person) { FactoryBot.create(:person, :with_assister_role) }
  let(:csr_person) { FactoryBot.create(:person, :with_csr_role) }
  let(:employee_person) { FactoryBot.create(:person, :with_employee_role) }

  permissions :privacy? do
    it "grants access when consumer" do
      expect(subject).to permit(FactoryBot.build(:user, :consumer, person: consumer_person), ConsumerRole)
    end

    it "grants access when broker" do
      expect(subject).to permit(FactoryBot.build(:user, :broker, person: broker_person), ConsumerRole)
    end

    it "grants access when assister" do
      expect(subject).to permit(FactoryBot.build(:user, :assister, person: assister_person), ConsumerRole)
    end

    it "grants access when csr" do
      expect(subject).to permit(FactoryBot.build(:user, :csr, person: csr_person), ConsumerRole)
    end

    it "grants access when user without roles" do
      expect(subject).to permit(User.new, ConsumerRole)
    end

    it "denies access when employee" do
      expect(subject).not_to permit(FactoryBot.build(:user, :employee, person: employee_person), ConsumerRole)
    end

    it "denies access when employer_staff" do
      expect(subject).not_to permit(FactoryBot.build(:user, :employer_staff), ConsumerRole)
    end
  end

  permissions :edit? do
    let(:hbx_staff_user) {FactoryBot.create(:user, person: person)}
    let(:person) { FactoryBot.create(:person, :with_hbx_staff_role) }
    let(:hbx_staff_role) { FactoryBot.create(:hbx_staff_role, person: person)}
    let(:permission) { FactoryBot.create(:permission)}

    it "grants access when hbx_staff" do
      allow(hbx_staff_role).to receive(:permission).and_return permission
      allow(person).to receive(:hbx_staff_role).and_return hbx_staff_role
      allow(hbx_staff_user).to receive(:person).and_return person
      allow(permission).to receive(:can_update_ssn).and_return true
      expect(subject).to permit(hbx_staff_user, consumer_role)
    end

    it "denies access when normal user" do
      expect(subject).not_to permit(User.new, consumer_role)
    end

    context "consumer" do
      let(:user) { FactoryBot.create(:user, :consumer, person: consumer_role.person) }
      let(:consumer_role) { FactoryBot.create(:consumer_role) }
      let(:other_consumer_role) { FactoryBot.build(:consumer_role) }

      it "grants access" do
        expect(subject).to permit(user, consumer_role)
      end

      it "denies access" do
        expect(subject).not_to permit(user, other_consumer_role)
      end
    end
  end

  permissions :ridp_accessible? do
    let(:hbx_staff_user) {FactoryBot.create(:user, person: person)}
    let(:person) { FactoryBot.create(:person, :with_hbx_staff_role) }
    let(:hbx_staff_role) { FactoryBot.create(:hbx_staff_role, person: person)}
    let(:permission) { FactoryBot.create(:permission)}
    let(:user_without_staff_role) { FactoryBot.create(:user, person: consumer_person) }

    it "grants access when hbx_staff" do
      allow(hbx_staff_role).to receive(:permission).and_return permission
      allow(person).to receive(:hbx_staff_role).and_return hbx_staff_role
      allow(hbx_staff_user).to receive(:person).and_return person
      expect(subject).to permit(hbx_staff_user, consumer_role)
    end

    it "denies access when normal user" do
      expect(subject).not_to permit(user_without_staff_role, consumer_role)
    end

    context "consumer" do
      let(:user) { FactoryBot.create(:user, :consumer, person: consumer_role.person) }
      let(:consumer_role) { FactoryBot.create(:consumer_role) }
      let(:other_consumer_role) { FactoryBot.build(:consumer_role) }

      it "grants access when identity validation is complete" do
        allow(user).to receive(:has_hbx_staff_role?).and_return false
        allow(consumer_role).to receive(:identity_validation).and_return 'valid'
        expect(subject).to permit(user, consumer_role)
      end

      it "denies access when identity validation is incomplete" do
        allow(user).to receive(:has_hbx_staff_role?).and_return false
        allow(other_consumer_role).to receive(:identity_validation).and_return 'invalid'
        expect(subject).not_to permit(user, other_consumer_role)
      end
    end
  end
end
end
