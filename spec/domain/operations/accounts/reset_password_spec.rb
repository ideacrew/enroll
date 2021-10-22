# frozen_string_literal: true

require 'rails_helper'
require_relative 'shared_context_account'

RSpec.describe Operations::Accounts::Create, type: :request do
  subject { described_class.new }
  include_context 'account'

  context 'given a set of accounts exist in keycloak' do
    before do
      avenger_accounts = create_avenger_accounts
      @avenger_account = avenger_accounts.first
    end

    after { delete_avenger_accounts }

    context 'and a new password credentials are posted'

    let(:new_password) { '$uperP@ss11' }
    let(:type) { 'password' }
    let(:credentials) { { type: type, temporary: false, value: new_password } }
    let(:account) { { id: @avenger_account[:id], credentials: credentials } }

    it 'should update the account password' do
      result = subject.call(account)
      binding.pry

      expect(result.success?).to be_truthy
    end
  end
end
