# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Operations::Users::Create do
  subject { described_class.new }

  context 'Given valid parameters for a new user' do
    let(:username) { 'spiderman' }
    let(:password) { '$3cr3tP@55w0rd' }
    let(:email) { 'peter.parker@avengers.org' }
    let(:first_name) { 'Peter' }
    let(:last_name) { 'Parker' }
    let(:roles) { %w[consumer avenger] }

    # let(:client_roles) { %w[consumer avenger] }
    let(:client_id) { 'polypress' }

    let(:new_account) do
      {
        username: username,
        password: password,
        email: email,
        first_name: first_name,
        last_name: last_name,
        roles: roles
      }
    end


    context "and there's not an existing user account with same usernam" do
      it 'should create a new Keycloak Account and an associated User record' do
        VCR.use_cassette('users.add_new') do
          result = subject.call(new_account)

          expect(result.success?).to be_truthy
          account_id = result.success[:account][:id]
          expect(result.success[:user][:account_id]).to_not eq account_id
        end
      end
    end

    context 'and the user account does exist' do

      it 'should return a failure monad' do
        VCR.use_cassette('users.existing_user') do
          result = subject.call(new_account)

          expect(result.failure?).to be_truthy
          expect(result.failure[:new_user]).to be_falsey

          Operations::Accounts::Delete.new.call(login: username)
        end
      end
    end
  end
end
