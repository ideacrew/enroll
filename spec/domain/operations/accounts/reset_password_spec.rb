# frozen_string_literal: true

require 'rails_helper'
require_relative 'shared_context_account'

RSpec.describe Operations::Accounts::ResetPassword, type: :request do
  subject { described_class.new }
  include_context 'account'

  context 'given a set of accounts exist in keycloak' do
    before { create_avenger_accounts }

    # after { delete_avenger_accounts }

    context 'and a new password credentials are posted' do
      let(:new_password) { '$uperP@ss11' }
      let(:type) { 'password' }
      let(:credentials) do
        { type: type, temporary: false, value: new_password }
      end

      let(:avenger_username) { avengers.first.last[:username] }
      let(:avenger_account) do
        Keycloak::Internal.get_user_info(avenger_username, true)
      end
      let(:new_password_params) do
        {
          username: avenger_username,
          id: avenger_account['id'],
          credentials: [credentials]
        }
      end

      it 'should update the account password' do
        result = subject.call(account: new_password_params)

        binding.pry
        expect(result.success?).to be_truthy
      end
    end
  end
end
