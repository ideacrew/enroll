require 'rails_helper'

RSpec.describe PaymentTransaction, :type => :model, dbclean: :after_each do
  let!(:family) { FactoryBot.create(:family, :with_primary_family_member_and_dependent) }

  context 'with generated payment transactions' do
    it 'should set submitted_at' do
      family.payment_transactions << PaymentTransaction.new
      expect(family.payment_transactions.first.submitted_at).not_to eq nil
    end

    it 'should generate payment_transaction_id' do
      family.payment_transactions << PaymentTransaction.new
      expect(family.payment_transactions.first.payment_transaction_id).not_to eq nil
    end
  end
end
