# frozen_string_literal: true

require 'rails_helper'
require_relative 'shared_context_account'

RSpec.describe Operations::Accounts::Find, type: :request do
  subject { described_class.new }
  include_context 'account'

  context 'given a set of accounts exist in keycloak' do
    before { create_avenger_accounts }
    after { delete_avenger_accounts }

    context 'scope_name is :all' do
      it 'should return all accounts limited by default page_size' do
        response = subject.call(scope_name: :all)

        expect(response.success?).to be_truthy
        expect(response.success.count).to eq avengers.keys.count
      end
    end

    context 'scope_name is :by_username' do
      let(:black_widow_username) { avengers[:black_widow][:username] }
      let(:black_widow_email) { avengers[:black_widow][:email] }

      context 'it should find an account by user login' do
        it 'should find the account' do
          response =
            subject.call(
              scope_name: :by_username,
              criterion: black_widow_username
            )

          expect(response.success?).to be_truthy
          expect(response.success.first[:email]).to eq black_widow_email
        end
      end

      context 'it should find an account by email' do
        it 'should find the account' do
          response =
            subject.call(scope_name: :by_email, criterion: black_widow_email)

          expect(response.success?).to be_truthy
          expect(response.success.first[:username]).to eq black_widow_username
        end
      end
    end

    context 'scope_name is :by_any' do
      it 'should return all accounts limited by default page_size' do
        response = subject.call(scope_name: :by_any, criterion: 'avengers')

        expect(response.success?).to be_truthy
        expect(response.success.count).to eq avengers.keys.count
      end
    end
  end
end
