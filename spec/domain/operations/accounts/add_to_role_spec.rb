# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Operations::Accounts::AddToRole, type: :request do
  subject { described_class.new }

  context 'Given a Keycloak client configuration with credentials and network-accessible Keycloak instance' do
    it 'should connect to the server' do
      VCR.use_cassette('account.add_to_role.get_credentials') do
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

      let!(:account) do
        VCR.use_cassette('account.add_to_role.create_account') do
          Operations::Accounts::Create.new.call(
            account: {
              username: username,
              password: password,
              email: email,
              first_name: first_name,
              last_name: last_name
            }
          )
        end
      end

      it 'should create the new user' do
        VCR.use_cassette('account.add_to_role.add_account_to_role') do
          staff_accounts =
            Operations::Accounts::Find.new.call(
              scope_name: :by_realm_role,
              criterion: 'hbx_staff'
            )
          expect(staff_accounts.success).to be_blank

          response =
            subject.call(id: account.success[:user][:id], roles: ['hbx_staff'])
          expect(response.success?).to be_truthy

          staff_accounts =
            Operations::Accounts::Find.new.call(
              scope_name: :by_realm_role,
              criterion: 'hbx_staff'
            )
          expect(staff_accounts.success).not_to be_empty
          expect(staff_accounts.success).to be_an_instance_of(Array)
          expect(
            staff_accounts.success.any? do |staff|
              staff[:id] == account.success[:user][:id]
            end
          ).to be_truthy

          Operations::Accounts::Delete.new.call(login: username)
        end
      end
    end
  end
end
