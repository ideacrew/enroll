# frozen_string_literal: true

require "rails_helper"

RSpec.describe PersonPolicy, type: :policy do
  context 'with hbx_staff_role' do
    let(:record_person) {FactoryBot.create(:person)}
    let(:admin_person){FactoryBot.create(:person)}
    let(:admin_user){FactoryBot.create(:user, person: admin_person)}
    let(:hbx_staff_role) { FactoryBot.create(:hbx_staff_role, person: admin_person)}
    let(:hbx_profile) {FactoryBot.create(:hbx_profile)}
    Permission.all.delete

    context 'allowed to modify? for hbx_staff_role subroles' do
      let(:policy){PersonPolicy.new(admin_user, record_person)}

      it 'hbx_staff with modify family permission' do
        allow(hbx_staff_role).to receive(:permission).and_return(FactoryBot.create(:permission, :hbx_staff, modify_family: true))
        expect(policy.can_update?).to be true
      end

      it 'hbx_staff without modify family permission' do
        allow(hbx_staff_role).to receive(:permission).and_return(FactoryBot.create(:permission, :hbx_staff, modify_family: false))
        expect(policy.can_update?).to be false
      end

      it 'hbx_read_only with modify family permission' do
        allow(hbx_staff_role).to receive(:permission).and_return(FactoryBot.create(:permission, :hbx_read_only, modify_family: true))
        expect(policy.can_update?).to be true
      end

      it 'hbx_read_only without modify family permission' do
        allow(hbx_staff_role).to receive(:permission).and_return(FactoryBot.create(:permission, :hbx_read_only, modify_family: false))
        expect(policy.can_update?).to be false
      end
    end

    # updateable? method does not have a proper authorization logic, it is always returning true except for :developer permission
    # context 'hbx_staff_role subroles' do
    #   it 'hbx_staff' do
    #     allow(hbx_staff_role).to receive(:permission).and_return(FactoryBot.create(:permission, :hbx_staff))
    #     expect(policy.updateable?).to be true
    #   end

    #   it 'hbx_read_only' do
    #     allow(hbx_staff_role).to receive(:permission).and_return(FactoryBot.create(:permission, :hbx_read_only))
    #     expect(policy.updateable?).to be true
    #   end

    #   it 'hbx_csr_supervisor' do
    #     allow(hbx_staff_role).to receive(:permission).and_return(FactoryBot.create(:permission, :hbx_csr_supervisor))
    #     expect(policy.updateable?).to be true
    #   end

    #   it 'hbx_csr_tier2' do
    #     allow(hbx_staff_role).to receive(:permission).and_return(FactoryBot.create(:permission, :hbx_csr_tier2))
    #     expect(policy.updateable?).to be true
    #   end

    #   it 'csr_tier1' do
    #     allow(hbx_staff_role).to receive(:permission).and_return(FactoryBot.create(:permission, :hbx_csr_tier1))
    #     expect(policy.updateable?).to be true
    #   end

    #   it 'developer' do
    #     allow(hbx_staff_role).to receive(:permission).and_return(FactoryBot.create(:permission, :developer))
    #     expect(policy.updateable?).to be false
    #   end
    # end


    context 'permissions' do
      let(:policy){PersonPolicy.new(admin_user, record_person)}
      subject { described_class }

      permissions :can_access_identity_verifications? do

        let(:person_A){FactoryBot.create(:person)}
        let!(:user_A){FactoryBot.create(:user, person: person_A)}

        let(:person_B){ FactoryBot.create(:person) }
        let!(:user_B){ FactoryBot.create(:user, person: person_B) }

        context 'logged in current user not matched with passed record' do
          context 'when user is not an admin' do
            it "denies access if current person not matched with passed record" do
              expect(subject).not_to permit(user_A, person_B)
            end
          end

          context 'when user is an admin' do
            let!(:hbx_staff_role) { FactoryBot.create(:hbx_staff_role, person: person_A)}

            it "grants access if the current user is an admin" do
              expect(subject).to permit(user_A, person_B)
            end
          end
        end

        context 'logged in person matched with passed record' do
          it "grants access" do
            expect(subject).to permit(user_A, person_A)
          end
        end
      end
    end
  end

  context 'with broker role' do
    Permission.all.delete

    let(:consumer_role) do
      FactoryBot.create(:consumer_role)
    end

    let(:person) do
      pers = consumer_role.person
      pers.user = user
      pers.save!
      pers
    end

    let(:broker_agency_profile) do
      FactoryBot.create(:benefit_sponsors_organizations_broker_agency_profile)
    end

    let(:user) do
      FactoryBot.create(:user)
    end

    let(:existing_broker_staff_role) do
      person.broker_agency_staff_roles.first
    end

    let(:broker_role) do
      role = BrokerRole.new(
        :broker_agency_profile => broker_agency_profile,
        :aasm_state => "applicant",
        :npn => "123456789",
        :provider_kind => "broker"
      )
      person.broker_role = role
      person.save!
      person.broker_role
    end

    let(:policy){PersonPolicy.new(user,person)}

    it 'broker should be able to update' do
      expect(policy.can_update?).to be true
    end

  end
end
