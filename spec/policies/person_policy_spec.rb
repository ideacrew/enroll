# frozen_string_literal: true

require 'rails_helper'

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

  context "for broker login" do
    let(:broker_agency_profile) { FactoryBot.create(:benefit_sponsors_organizations_broker_agency_profile, market_kind: :individual) }
    let!(:broker_role) { FactoryBot.create(:broker_role, benefit_sponsors_broker_agency_profile_id: broker_agency_profile.id, aasm_state: :active) }
    let!(:broker_role_user) {FactoryBot.create(:user, :person => broker_role.person, roles: ['broker_role'])}

    let!(:broker_agency_staff_role) { FactoryBot.create(:broker_agency_staff_role, benefit_sponsors_broker_agency_profile_id: broker_agency_profile.id, aasm_state: 'active')}
    let!(:broker_agency_staff_user) {FactoryBot.create(:user, :person => broker_agency_staff_role.person, roles: ['broker_agency_staff_role'])}

    let(:person) { FactoryBot.create(:person, :with_consumer_role) }
    let(:user) { FactoryBot.create(:user, person: person) }
    let!(:family) { FactoryBot.create(:family, :with_primary_family_member, person: person) }

    before do
      person.consumer_role.move_identity_documents_to_verified
    end

    context 'with broker role' do
      let(:policy) {PersonPolicy.new(broker_role_user, person)}

      context 'authorized broker' do
        before(:each) do
          family.broker_agency_accounts << BenefitSponsors::Accounts::BrokerAgencyAccount.new(benefit_sponsors_broker_agency_profile_id: broker_agency_profile.id,
                                                                                              start_on: Time.now,
                                                                                              writing_agent_id: broker_role.id,
                                                                                              is_active: true)
          family.reload
        end

        it 'broker should be able to update' do
          expect(policy.can_update?).to be true
        end
      end

      context 'unauthorized broker' do
        it 'broker should not be able to update' do
          expect(policy.can_update?).to be false
        end
      end
    end

    context 'with broker staff role' do
      let(:policy){PersonPolicy.new(broker_agency_staff_user, person)}

      context 'authorized broker' do
        before(:each) do
          family.broker_agency_accounts << BenefitSponsors::Accounts::BrokerAgencyAccount.new(benefit_sponsors_broker_agency_profile_id: broker_agency_profile.id,
                                                                                              start_on: Time.now,
                                                                                              is_active: true)
          family.reload
        end

        it 'broker should be able to update' do
          expect(policy.can_update?).to be true
        end
      end

      context 'unauthorized broker' do
        it 'broker should not be able to update' do
          expect(policy.can_update?).to be false
        end
      end
    end
  end
end

describe PersonPolicy, "given an unlinked user" do
  let(:user) do
    instance_double(
      User,
      person: nil
    )
  end

  let(:record) do
    instance_double(
      Person,
      primary_family: nil,
      consumer_role: consumer_role
    )
  end

  let(:consumer_role) do
    instance_double(
      ConsumerRole
    )
  end

  subject { described_class.new(user, record) }

  it "may not complete_ridp" do
    expect(subject.complete_ridp?).to be_falsey
  end
end

describe PersonPolicy, "given a user who is a different person, with no special permissions" do
  let(:user) do
    instance_double(
      User,
      person: user_person
    )
  end

  let(:record) do
    instance_double(
      Person,
      primary_family: nil,
      consumer_role: consumer_role
    )
  end

  let(:consumer_role) do
    instance_double(
      ConsumerRole
    )
  end

  let(:user_consumer_role) do
    instance_double(
      ConsumerRole
    )
  end

  let(:user_person) do
    instance_double(
      Person,
      primary_family: nil,
      broker_agency_staff_roles: broker_agency_staff_roles_scope,
      broker_role: nil,
      hbx_staff_role: nil,
      consumer_role: user_consumer_role
    )
  end

  let(:broker_agency_staff_roles_scope) do
    double(
      active: []
    )
  end

  subject { described_class.new(user, record) }

  it "may not complete_ridp" do
    expect(subject.complete_ridp?).to be_falsey
  end
end

describe PersonPolicy, "given a user who is an admin, but may not modify families" do
  let(:user) do
    instance_double(
      User,
      person: user_person
    )
  end

  let(:record) do
    instance_double(
      Person,
      primary_family: nil,
      consumer_role: nil
    )
  end

  let(:user_person) do
    instance_double(
      Person,
      primary_family: nil,
      broker_agency_staff_roles: broker_agency_staff_roles_scope,
      broker_role: nil,
      hbx_staff_role: hbx_staff_role
    )
  end

  let(:broker_agency_staff_roles_scope) do
    double(
      active: []
    )
  end

  let(:hbx_staff_role) do
    instance_double(
      HbxStaffRole,
      permission: permission
    )
  end

  let(:permission) do
    instance_double(
      Permission,
      modify_family: false
    )
  end

  subject { described_class.new(user, record) }

  it "may not complete_ridp" do
    expect(subject.complete_ridp?).to be_falsey
  end
end

describe PersonPolicy, "given a user who is an admin, and may modify families" do
  let(:user) do
    instance_double(
      User,
      person: user_person
    )
  end

  let(:consumer_role) do
    instance_double(
      ConsumerRole
    )
  end

  let(:record) do
    instance_double(
      Person,
      primary_family: nil,
      consumer_role: consumer_role
    )
  end

  let(:user_person) do
    instance_double(
      Person,
      primary_family: nil,
      broker_agency_staff_roles: broker_agency_staff_roles_scope,
      broker_role: nil,
      hbx_staff_role: hbx_staff_role
    )
  end

  let(:broker_agency_staff_roles_scope) do
    double(
      active: []
    )
  end

  let(:hbx_staff_role) do
    instance_double(
      HbxStaffRole,
      permission: permission
    )
  end

  let(:permission) do
    instance_double(
      Permission,
      modify_family: true
    )
  end

  subject { described_class.new(user, record) }

  it "may complete_ridp" do
    expect(subject.complete_ridp?).to be_truthy
  end
end

describe PersonPolicy, "given a user who is an active broker for that person" do
  let(:user) do
    instance_double(
      User,
      person: user_person
    )
  end

  let(:record) do
    instance_double(
      Person,
      primary_family: family,
      consumer_role: consumer_role
    )
  end

  let(:consumer_role) do
    instance_double(
      ConsumerRole
    )
  end

  let(:family) do
    instance_double(
      Family,
      active_broker_agency_account: broker_agency_account
    )
  end

  let(:broker_agency_account) do
    instance_double(
      BenefitSponsors::Accounts::BrokerAgencyAccount,
      benefit_sponsors_broker_agency_profile_id: broker_agency_id,
      writing_agent_id: writing_agent_id
    )
  end

  let(:broker_agency_id) { "Some Broker Agency ID" }
  let(:writing_agent_id) { "Some Writing Agent ID" }

  let(:user_person) do
    instance_double(
      Person,
      primary_family: nil,
      broker_agency_staff_roles: broker_agency_staff_roles_scope,
      broker_role: broker_role,
      hbx_staff_role: nil,
      consumer_role: nil
    )
  end

  let(:broker_role) do
    instance_double(
      BrokerRole,
      id: writing_agent_id,
      :active? => true,
      :individual_market? => true,
      benefit_sponsors_broker_agency_profile_id: broker_agency_id
    )
  end

  let(:broker_agency_staff_roles_scope) do
    double(
      active: []
    )
  end

  let(:hbx_staff_role) do
    instance_double(
      HbxStaffRole,
      permission: permission
    )
  end

  let(:permission) do
    instance_double(
      Permission,
      modify_family: true
    )
  end

  subject { described_class.new(user, record) }

  it "may complete_ridp" do
    expect(subject.complete_ridp?).to be_truthy
  end
end

describe PersonPolicy, "given a user who is active broker staff for that person" do
  let(:user) do
    instance_double(
      User,
      person: user_person
    )
  end

  let(:record) do
    instance_double(
      Person,
      primary_family: family,
      consumer_role: consumer_role
    )
  end

  let(:consumer_role) do
    instance_double(
      ConsumerRole
    )
  end

  let(:family) do
    instance_double(
      Family,
      active_broker_agency_account: broker_agency_account
    )
  end

  let(:broker_agency_account) do
    instance_double(
      BenefitSponsors::Accounts::BrokerAgencyAccount,
      broker_agency_profile: broker_agency_profile
    )
  end

  let(:broker_agency_id) { "Some Broker Agency ID" }
  let(:writing_agent_id) { "Some Writing Agent ID" }

  let(:user_person) do
    instance_double(
      Person,
      primary_family: nil,
      broker_agency_staff_roles: broker_agency_staff_roles_scope,
      broker_role: nil,
      hbx_staff_role: nil,
      consumer_role: nil
    )
  end

  let(:broker_agency_staff_role) do
    instance_double(
      BrokerAgencyStaffRole,
      :active? => true,
      benefit_sponsors_broker_agency_profile_id: broker_agency_id
    )
  end

  let(:broker_agency_staff_roles_scope) do
    double(
      active: [broker_agency_staff_role]
    )
  end

  let(:broker_agency_profile) do
    instance_double(
      BenefitSponsors::Organizations::BrokerAgencyProfile,
      id: broker_agency_id
    )
  end

  let(:hbx_staff_role) do
    instance_double(
      HbxStaffRole,
      permission: permission
    )
  end

  let(:permission) do
    instance_double(
      Permission,
      modify_family: true
    )
  end

  subject { described_class.new(user, record) }

  it "may complete_ridp" do
    expect(subject.complete_ridp?).to be_truthy
  end
end

describe PersonPolicy, "given a user who is a primary family member" do

  let(:user_person) { FactoryBot.create(:person, :with_consumer_role, :with_active_consumer_role) }
  let(:dependent_person) { FactoryBot.create(:person, :with_consumer_role, :with_active_consumer_role) }
  let(:family_members) { [user_person, dependent_person] }
  let(:family) { FactoryBot.create(:family, :with_primary_family_member_and_dependent, person: user_person, people: family_members) }
  let(:user) { FactoryBot.create(:user, person: user_person) }

  context "deletes own documents" do
    before do
      family.primary_person.consumer_role.move_identity_documents_to_verified
    end

    subject { described_class.new(user, user_person) }

    it "may delete document" do
      expect(subject.can_delete_document?).to be_truthy
    end
  end

  context "deletes dependent's documents" do

    let(:record) { family.family_members.last.person}

    subject { described_class.new(user, record) }

    before do
      user_person.consumer_role.update_attributes!(identity_validation: 'valid')
    end

    it "may delete documents" do
      expect(subject.can_delete_document?).to be_truthy
    end
  end
end