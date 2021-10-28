# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Operations::Accounts::Create, type: :request do
  subject { described_class.new }

  context 'Given a Keycloak client configuration with credentials and network-accessible Keycloak instance' do
    it 'should connect to the server' do
      VCR.use_cassette('account.create_spec.get_credentials') do
        # Keycloak.proc_cookie_token = lambda { cookies[:keycloak_token] }
        token = JSON(Keycloak::Client.get_token_by_client_credentials)

        expect(token['access_token']).not_to be_nil
        expect(token['token_type']).to eq 'Bearer'
      end
    end
  end

  context 'Creating a Keycloak Account' do
    context 'Given valid parameters for a new user' do
      let(:username) { 'ironman' }
      let(:password) { '$3cr3tP@55w0rd' }
      let(:email) { 'tony.stark@avengers.org' }
      let(:first_name) { 'Tony' }
      let(:last_name) { 'Stark' }

      let(:account) do
        {
          username: username,
          password: password,
          email: email,
          first_name: first_name,
          last_name: last_name
        }
      end

      it 'should create the new user' do
        VCR.use_cassette('account.create_spec.create_user') do
          response = subject.call(account: account)

          expect(response.success?).to be_truthy
          expect(response.success[:user][:username]).to eq account[:username]
          expect(response.success[:user][:email]).to eq account[:email]

          # expect(response.success[:user][:created_at]).to be_a Time
          Operations::Accounts::Delete.new.call(login: username)
        end
      end
    end
  end
end
