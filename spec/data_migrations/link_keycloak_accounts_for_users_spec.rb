# frozen_string_literal: true

require 'rails_helper'

describe LinkKeycloakAccountsForUsers, dbclean: :after_each do
  before :all do
    DatabaseCleaner.clean
  end

  let(:given_task_name) { 'link_keycloak_accounts_for_users' }
  subject do
    LinkKeycloakAccountsForUsers.new(
      given_task_name,
      double(current_scope: nil)
    )
  end

  context 'given a task name' do
    it 'has the given task name' do
      expect(subject.name).to eql given_task_name
    end
  end

  describe 'link existing user with keycloak' do
    before do
      allow(User).to receive(:all).and_return(double(:no_timeout => [user]))
    end

    context 'given the user not linked with keycloak' do
      let!(:person) { FactoryBot.create(:person, :with_broker_role, user: user) }
      let(:user) { FactoryBot.create(:user, roles: ['broker'], oim_id: "greatgatsby") }

      before do
        agency_profile = FactoryBot.create(:broker_agency_profile, primary_broker_role: user.person.broker_role)
        person.broker_role.update(broker_agency_profile_id: agency_profile.id)
      end

      it 'should change oim_id and account_id' do
        VCR.use_cassette('link_keycloak_accounts_for_users.new_account') do
          subject.migrate
          user.reload
          expect(user.account_id).to be_present
          expect(user.oim_id).to be_present

          Operations::Accounts::Delete.new.call(id: user.account_id)
        end
      end
    end

    context 'given the user already linked with keycloak' do
      let!(:person) { FactoryBot.create(:person, :with_broker_role, user: user) }
      let(:user) { FactoryBot.create(:user, account_id: 'sample-account-id', roles: ['hbx_staff'], oim_id: "greatgatsby") }

      before do
        agency_profile = FactoryBot.create(:broker_agency_profile, primary_broker_role: user.person.broker_role)
        person.broker_role.update(broker_agency_profile_id: agency_profile.id)
      end

      it 'should update oim_id and account_id' do
        VCR.use_cassette('link_keycloak_accounts_for_users.existing_account') do
          subject.migrate
          user.reload
          expect(user.account_id).to be_present
          expect(user.account_id).not_to eq 'sample-account-id'
          expect(user.account_id).to eq user.oim_id

          Operations::Accounts::Delete.new.call(id: user.account_id)
        end
      end
    end
  end
end
