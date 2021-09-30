# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Operations::Accounts::ForgotPassword, type: :request do
  subject { described_class.new }

  context 'Given a Keycloak client configuration with credentials and network-accessible Keycloak instance' do
    it 'should connect to the server' do
      token = JSON(Keycloak::Client.get_token_by_client_credentials)

      expect(token['access_token']).not_to be_nil
      expect(token['token_type']).to eq 'Bearer'
    end
  end

  context 'Given an invalid username' do
    let(:invalid_username) { { username: 'abc123xyz' } }

    it 'should fail to delete account' do
      response = subject.call(invalid_username)

      expect(response.failure?).to be_truthy
    end
  end

  context 'Given a valid username' do
    let(:username) { 'thor' }
    let(:password) { '$3cr3tP@55w0rd' }
    let(:email) { 'thor@avengers.org' }
    let(:first_name) { 'Thor' }
    let(:last_name) { 'Odinson' }

    let(:new_account_params) do
      {
        username: username,
        password: password,
        email: email,
        first_name: first_name,
        last_name: last_name
      }
    end

    before { Operations::Accounts::Create.new.call(new_account_params) }

    let(:account_params) { { username: username } }

    it 'should delete the account' do
      response = subject.call(account_params)
      expect(response.success?).to be_truthy
    end
  end
end
