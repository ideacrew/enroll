# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Operations::Accounts::Find, type: :request do
  subject { described_class.new }

  context 'scope_name is :by_username' do
    let(:username) { 'black_window' }
    let(:password) { '$3cr3tP@55w0rd' }
    let(:email) { 'scarlettk@avengers.org' }
    let(:first_name) { 'Natasha' }
    let(:last_name) { 'Romanoff' }

    let(:account) do
      {
        username: username,
        password: password,
        email: email,
        first_name: first_name,
        last_name: last_name
      }
    end

    let(:target_account) do
      ::Operations::Accounts::Create.new.call(account: account).success
    end

    before { target_account }
    after { Operations::Accounts::Delete.new.call(login: username) }

    context 'it should find an account by user login' do
      it 'should find the account' do
        response = subject.call(scope_name: :by_username, options: username)
        expect(response.success?).to be_truthy
        expect(response.success['email']).to eq email
      end
    end

    context 'it should find an account by email' do
      it 'should find the account' do
        response = subject.call(scope_name: :by_email, options: email)
        expect(response.success?).to be_truthy
        expect(response.success['username']).to eq username
      end
    end
  end
end
