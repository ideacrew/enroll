# frozen_string_literal: true

require 'rails_helper'

RSpec.describe FamilyMemberPolicy, type: :policy do
  let(:policy) { described_class.new(user, record) }
  let!(:person) { FactoryBot.create(:person, :with_consumer_role) }
  let!(:associated_user) { FactoryBot.create(:user, :person => person) }
  let!(:family) { FactoryBot.create(:family, :with_primary_family_member, person: person) }
  let!(:record) { family.family_members.first }

  context 'super_admin user' do
    let!(:admin_person) { FactoryBot.create(:person, :with_hbx_staff_role) }
    let!(:admin_user) { FactoryBot.create(:user, :with_hbx_staff_role, :person => admin_person) }
    let!(:update_admin) { admin_person.hbx_staff_role.update_attributes(permission_id: permission.id) }
    let(:user) { admin_user }

    context 'with permission' do
      let!(:permission) { FactoryBot.create(:permission, :super_admin) }

      context '#can_modify_family_members?' do
        it 'returns the result of #allowed_to_modify?' do
          expect(policy.can_modify_family_members?).to be_truthy
        end
      end
    end

    context 'without permission' do
      let!(:permission) { FactoryBot.create(:permission, :developer) }

      context '#can_modify_family_members?' do
        it 'returns the result of #allowed_to_modify?' do
          expect(policy.can_modify_family_members?).to be_falsey
        end
      end
    end
  end

  context 'record user' do
    let(:user) { associated_user }

    context '#can_modify_family_members?' do
      it 'returns the result of #allowed_to_modify?' do
        expect(policy.can_modify_family_members?).to be_truthy
      end
    end
  end

  context 'unauthorized user' do
    let!(:fake_person) { FactoryBot.create(:person, :with_consumer_role) }
    let!(:fake_user) {FactoryBot.create(:user, :person => fake_person)}
    let!(:fake_family) { FactoryBot.create(:family, :with_primary_family_member, person: fake_person) }
    let!(:fake_family_member) { fake_family.family_members.first }
    let(:user) { fake_user }

    context '#can_modify_family_members?' do
      it 'returns the result of #allowed_to_modify?' do
        expect(policy.can_modify_family_members?).to be_falsey
      end
    end
  end

  context 'broker logged in' do
    let!(:broker_user) { FactoryBot.create(:user, :person => writing_agent.person, roles: ['broker_role', 'broker_agency_staff_role']) }
    let(:broker_agency_profile) { FactoryBot.build(:benefit_sponsors_organizations_broker_agency_profile)}
    let(:writing_agent)         { FactoryBot.create(:broker_role, benefit_sponsors_broker_agency_profile_id: broker_agency_profile.id) }
    let(:assister)  do
      assister = FactoryBot.build(:broker_role, benefit_sponsors_broker_agency_profile_id: broker_agency_profile.id, npn: "SMECDOA00")
      assister.save(validate: false)
      assister
    end

    let(:user) { broker_user }

    context 'hired by family' do
      before(:each) do
        family.broker_agency_accounts << BenefitSponsors::Accounts::BrokerAgencyAccount.new(benefit_sponsors_broker_agency_profile_id: broker_agency_profile.id,
                                                                                            writing_agent_id: writing_agent.id,
                                                                                            start_on: Time.now,
                                                                                            is_active: true)
        family.reload
      end

      context '#can_modify_family_members?' do
        it 'returns the result of #allowed_to_modify?' do
          expect(policy.can_modify_family_members?).to be_truthy
        end
      end
    end

    context 'not hired by family' do

      context '#can_modify_family_members?' do
        it 'returns the result of #allowed_to_modify?' do
          expect(policy.can_modify_family_members?).to be_falsey
        end
      end
    end
  end
end