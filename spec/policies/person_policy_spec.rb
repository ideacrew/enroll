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

    context 'hbx_staff_role subroles' do
      let(:policy){PersonPolicy.new(admin_user, record_person)}

      it 'hbx_staff' do
        allow(hbx_staff_role).to receive(:permission).and_return(FactoryBot.create(:permission, :hbx_staff))
        expect(policy.updateable?).to be true
      end

      it 'hbx_read_only' do
        allow(hbx_staff_role).to receive(:permission).and_return(FactoryBot.create(:permission, :hbx_read_only))
        expect(policy.updateable?).to be true
      end

      it 'hbx_csr_supervisor' do
        allow(hbx_staff_role).to receive(:permission).and_return(FactoryBot.create(:permission, :hbx_csr_supervisor))
        expect(policy.updateable?).to be true
      end

      it 'hbx_csr_tier2' do
        allow(hbx_staff_role).to receive(:permission).and_return(FactoryBot.create(:permission, :hbx_csr_tier2))
        expect(policy.updateable?).to be true
      end

      it 'csr_tier1' do
        allow(hbx_staff_role).to receive(:permission).and_return(FactoryBot.create(:permission, :hbx_csr_tier1))
        expect(policy.updateable?).to be true
      end

      it 'developer' do
        allow(hbx_staff_role).to receive(:permission).and_return(FactoryBot.create(:permission, :developer))
        expect(policy.updateable?).to be false
      end
    end


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

  context 'with broker agency staff role' do
    let(:broker_agency_profile) do
      FactoryBot.create(:benefit_sponsors_organizations_broker_agency_profile)
    end

    let(:broker_agency_profile_2) do
      FactoryBot.create(:benefit_sponsors_organizations_broker_agency_profile)
    end

    let(:broker_agency_staff_role) { FactoryBot.create(:broker_agency_staff_role, benefit_sponsors_broker_agency_profile_id: broker_agency_profile.id, aasm_state: 'active')}
    let(:broker_user) {FactoryBot.create(:user, :person => broker_agency_staff_role.person, roles: ['broker_role'])}
    let(:broker_person) { broker_agency_staff_role.person }
    let(:broker_role) do
      role = BrokerRole.new(
        :broker_agency_profile => broker_agency_profile,
        :aasm_state => "applicant",
        :npn => "123456789",
        :provider_kind => "broker"
      )
      broker_person.broker_role = role
      broker_person.save!
      broker_person.broker_role
    end

    let(:person) { FactoryBot.create(:person, :with_consumer_role) }
    let(:user) { FactoryBot.create(:user, person: person) }
    let!(:family) { FactoryBot.create(:family, :with_primary_family_member, person: person) }

    let(:policy){PersonPolicy.new(broker_user, person)}

    context 'authorized broker agency staff role' do
      before(:each) do
        family.broker_agency_accounts << BenefitSponsors::Accounts::BrokerAgencyAccount.new(benefit_sponsors_broker_agency_profile_id: broker_agency_profile.id,
                                                                                            start_on: Time.now,
                                                                                            is_active: true)
        family.reload
      end

      it 'broker agency staff role should be able to update' do
        expect(policy.can_update?).to be true
      end

      it 'broker agency staff role should return true when it matches broker agency profile' do
        @result = policy.send(:matches_broker_agency_profile?, broker_agency_profile.id)
        expect(@result).to eq true
      end
    end

    context 'unauthorized broker agency staff role' do
      before do
        broker_agency_staff_role.update_attributes!(benefit_sponsors_broker_agency_profile_id: broker_agency_profile_2.id)
      end

      it 'broker agency staff role should not be able to update' do
        expect(policy.can_update?).to be false
      end

      it 'broker agency staff role should return false when it does not matches broker agency profile' do
        @result = policy.send(:matches_broker_agency_profile?, broker_agency_profile.id)
        expect(@result).to eq false
      end
    end
  end
end