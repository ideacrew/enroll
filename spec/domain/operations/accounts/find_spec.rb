# frozen_string_literal: true

require 'rails_helper'
require_relative 'shared_context_account'

RSpec.describe Operations::Accounts::Find, type: :request do
  subject { described_class.new }
  include_context 'account'

  context 'given a set of accounts exist in keycloak' do
    context 'scope_name is :all' do
      it 'should return all accounts limited by default page_size' do
        VCR.use_cassette('account.find_all') do
          create_avenger_accounts

          response = subject.call(scope_name: :all)

          expect(response.success?).to be_truthy
          expect(response.success.count).to eq avengers.keys.count
          delete_avenger_accounts
        end
      end
    end

    context 'scope_name is :by_username' do
      let(:black_widow_username) { avengers[:black_widow][:username] }
      let(:black_widow_email) { avengers[:black_widow][:email] }

      context 'it should find an account by user login' do
        it 'should find the account' do
          VCR.use_cassette('account.by_username') do
            create_avenger_accounts
            response =
              subject.call(
                scope_name: :by_username,
                criterion: black_widow_username
              )

            expect(response.success?).to be_truthy
            expect(response.success.first[:email]).to eq black_widow_email
            delete_avenger_accounts
          end
        end
      end

      context 'it should find an account by email' do
        it 'should find the account' do
          VCR.use_cassette('account.by_email') do
            create_avenger_accounts
            response =
              subject.call(scope_name: :by_email, criterion: black_widow_email)

            expect(response.success?).to be_truthy
            expect(response.success.first[:username]).to eq black_widow_username
            delete_avenger_accounts
          end
        end
      end
    end

    context 'scope_name is :by_any' do
      it 'should return all accounts limited by default page_size' do
        VCR.use_cassette('account.by_any') do
          create_avenger_accounts
          response = subject.call(scope_name: :by_any, criterion: 'avengers')

          expect(response.success?).to be_truthy
          expect(response.success.count).to eq avengers.keys.count
          delete_avenger_accounts
        end
      end
    end

    context 'scope_name is :count_all' do
      it 'should return total number of accounts' do
        VCR.use_cassette('account.count_all') do
          create_avenger_accounts
          response = subject.call(scope_name: :count_all, criterion: 'avengers')

          expect(response.success?).to be_truthy
          expect(response.success).to be_an_instance_of(Integer)
          delete_avenger_accounts
        end
      end
    end

    context 'scope_name is :by_realm_role' do
      it 'should return total number of accounts' do
        VCR.use_cassette('account.by_realm_role') do
          create_avenger_accounts
          response = subject.call(scope_name: :by_realm_role, criterion: 'hbx_staff')

          expect(response.success?).to be_truthy
          expect(response.success).to be_an_instance_of(Array)

          avengers.each do |name, avenger|
            expect(response.success.any?{|user| user[:username] == name.to_s}).to be_truthy if avenger.key?(:realm_roles) && avenger[:realm_roles].include?('hbx_staff')
          end

          delete_avenger_accounts
        end
      end
    end
  end
end
