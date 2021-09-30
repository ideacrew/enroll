# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Operations::Accounts::Delete, type: :request do
  subject { described_class.new }

  context 'Given a Keycloak client configuration with credentials and network-accessible Keycloak instance' do
    it 'should connect to the server' do
      token = JSON(Keycloak::Client.get_token_by_client_credentials)

      expect(token['access_token']).not_to be_nil
      expect(token['token_type']).to eq 'Bearer'
    end
  end

  context 'Given an invalid account_id' do
    let(:invalid_account_id) { { account_id: 'abc123xyz' } }

    it 'should fail to delete account' do
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

    let(:account) do
      {
        username: username,
        password: password,
        email: email,
        first_name: first_name,
        last_name: last_name
      }
    end

    let(:id) { Operations::Accounts::Create.new.call(account: account).success['id'] }

    it 'should delete the account' do
      # cookies[:keycloak_token] =
      #   Keycloak::Client.get_token_by_client_credentials
      response = subject.call(id: id)

      expect(response.success?).to be_truthy
    end
  end
end
