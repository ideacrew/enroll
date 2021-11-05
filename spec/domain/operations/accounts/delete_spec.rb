# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Operations::Accounts::Delete, type: :request do
  subject { described_class.new }

  context 'Given a Keycloak client configuration with credentials and network-accessible Keycloak instance' do
    it 'should connect to the server' do
      VCR.use_cassette('account.delete_spec.get_credentials') do
        token = JSON(Keycloak::Client.get_token_by_client_credentials)

        expect(token['access_token']).not_to be_nil
        expect(token['token_type']).to eq 'Bearer'
      end
    end
  end

  context 'Given an invalid account_id' do
    let(:invalid_account_id) { { account_id: 'abc123xyz' } }

    it 'should fail to delete account' do
      response = subject.call(invalid_account_id)

      expect(response.failure?).to be_truthy
    end
  end

  context 'Given an existing aqccount' do
    let(:username) { 'captain_america' }
    let(:password) { '$3cr3tP@55w0rd' }
    let(:email) { 'steve.rodgersk@avengers.org' }
    let(:first_name) { 'Steve' }
    let(:last_name) { 'Rodgers' }

    let(:account) do
      {
        username: username,
        password: password,
        email: email,
        first_name: first_name,
        last_name: last_name
      }
    end

    # let(:target_account) do
    #   ::Operations::Accounts::Create.new.call(account: account).success
    # end

    context 'it should delete an account by user login' do

      it 'should delete the account by login' do
        VCR.use_cassette('account.delete_spec.delete_by_login') do
          ::Operations::Accounts::Create.new.call(account: account).success
          response = subject.call(login: username)
          expect(response.success?).to be_truthy
        end
      end
    end

    context 'it should delete an account by user id' do
      # before { target_account }
      # let(:id) { target_account[:id] || nil }

      xit 'pending due receiving nil for id error' do
        expect(id).to_not be_nil

        response = subject.call(id: id)
        expect(response.success?).to be_truthy
      end
    end
  end
end
