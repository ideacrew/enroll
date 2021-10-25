# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Operations::Accounts::Enable, type: :request do
  subject { described_class.new }

  context 'Given a Keycloak client configuration with credentials and network-accessible Keycloak instance' do
    it 'should connect to the server' do
      VCR.use_cassette('account.enable_spec.get_credentials') do
        token = JSON(Keycloak::Client.get_token_by_client_credentials)

        expect(token['access_token']).not_to be_nil
        expect(token['token_type']).to eq 'Bearer'
      end
    end
  end

  context 'Given an invalid account_id' do
    let(:invalid_account_id) { { account_id: 'abc123xyz' } }

    it 'should fail to enable account' do
      response = subject.call(invalid_account_id)

      expect(response.failure?).to be_truthy
    end
  end

  context 'Given a valid account_id' do
    let(:username) { 'captain_america' }
    let(:password) { '$3cr3tP@55w0rd' }
    let(:email) { 'steve.rodgersk@avengers.org' }
    let(:first_name) { 'Steve' }
    let(:last_name) { 'Rodgers' }

    let(:account_params) do
      {
        username: username,
        password: password,
        email: email,
        first_name: first_name,
        last_name: last_name
      }
    end

    it 'should enable the account' do
      VCR.use_cassette('account.enable_spec.enable_by_id') do
        account_id = ::Operations::Accounts::Create.new.call(account: account_params).failure[:user][:id]
        response = subject.call({ id: account_id })

        expect(response.success?).to be_truthy
      end
    end
  end

  context 'Given a valid login' do
    let(:username) { 'captain_america' }
    let(:password) { '$3cr3tP@55w0rd' }
    let(:email) { 'steve.rodgersk@avengers.org' }
    let(:first_name) { 'Steve' }
    let(:last_name) { 'Rodgers' }

    let(:account_params) do
      {
        username: username,
        password: password,
        email: email,
        first_name: first_name,
        last_name: last_name
      }
    end


    let(:params) { { login: username } }

    it 'should enable the account' do
      VCR.use_cassette('account.enable_spec.enable_by_login') do
        ::Operations::Accounts::Create.new.call(account: account_params)
        response = subject.call(params)

        expect(response.success?).to be_truthy
      end
    end
  end
end
