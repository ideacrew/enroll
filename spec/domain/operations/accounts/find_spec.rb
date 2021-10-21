# frozen_string_literal: true

require 'rails_helper'
require_relative 'shared_context_account'

RSpec.describe Operations::Accounts::Find, type: :request do
  subject { described_class.new }
  include_context 'account'

  context 'scope_name is :all' do
    it 'should return all accounts limited by default page_size' do
      response = subject.call(scope_name: :all)
      require 'pry'
      binding.pry
      expect(response.success?).to be_truthy
      expect(response.success.count).to eq avengers.count
    end
  end

  context 'scope_name is :by_username' do
    let(:target_account) do
      ::Operations::Accounts::Create.new.call(account: account).success
    end

    before { create_avenger_accounts }

    # before { target_account }
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
