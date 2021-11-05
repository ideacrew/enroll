# frozen_string_literal: true

require 'rails_helper'
require_relative 'shared_context_account'

RSpec.describe Operations::Accounts::Update, type: :request do
  subject { described_class.new }
  include_context 'account'

  context 'given a set of accounts exist in keycloak' do
    context 'and updated attributes passed' do
      let(:avenger_username) { avengers.first.last[:username] }
      let(:avenger_email) { avengers.first.last[:email] }

      let(:avenger_account) do
        Keycloak::Internal.get_user_info(avenger_username, true)
      end

      let(:updated_username) { "new#{avenger_username}" }
      let(:updated_email) { "new#{avenger_email}" }

      let(:update_params) do
        {
          username: updated_username,
          id: avenger_account['id'],
          email: updated_email
        }
      end

      it 'should update the account' do
        VCR.use_cassette('account.update') do
          Operations::Accounts::Delete.new.call(login: updated_username)
          create_avenger_accounts
          result = subject.call(account: update_params)
          expect(result.success?).to be_truthy
          updated_account =
            Keycloak::Internal.get_user_info(updated_username, true)
          expect(updated_account['email']).to eq updated_email
          delete_avenger_accounts
        end
      end

      context 'updated attribute with existing username is passed' do
        let(:update_params) do
          { username: updated_username, id: avenger_account['id'] }
        end

        it 'should fail with 409 Conflict' do
          VCR.use_cassette('account.update.conflict_login') do
            create_avenger_accounts

            result = subject.call(account: update_params)
            expect(result.failure?).to be_truthy
            expect(result.failure).to eq 'Username or Email already exists'

            delete_avenger_accounts
          end
        end
      end

      context 'updated attribute with existing email is passed' do
        let(:update_params) do
          { id: avenger_account['id'], email: updated_email }
        end

        it 'should fail with 409 Conflict' do
          VCR.use_cassette('account.update.conflict_email') do
            create_avenger_accounts

            result = subject.call(account: update_params)
            expect(result.failure?).to be_truthy
            expect(result.failure).to eq 'Username or Email already exists'

            delete_avenger_accounts
            Operations::Accounts::Delete.new.call(login: updated_username)
          end
        end
      end
    end
  end
end
