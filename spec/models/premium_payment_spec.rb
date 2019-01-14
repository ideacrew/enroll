require 'rails_helper'

describe PremiumPayment, type: :model do

  let(:employer_profile_account)  { FactoryBot.build(:employer_profile_account) }
  let(:paid_on)                   { TimeKeeper.date_of_record.beginning_of_month }
  let(:amount)                    { 2345.07 }
  let(:method_kind)               { "ach" }
  let(:reference_id)              { "alphabetadelta" }
  let(:document_uri)              { "uri:document_store:12345" }

  let(:valid_params) do
    {
      employer_profile_account: employer_profile_account,
      paid_on: paid_on,
      amount: amount,
      method_kind: method_kind,
      reference_id: reference_id,
      document_uri: document_uri
    }
  end

  context ".new" do
    context "with no employer profile account" do
      let(:params) {valid_params.except(:employer_profile_account)}

      xit "should raise" do
        expect{PremiumPayment.create!(**params)}.to raise_error(Mongoid::Errors::NoParent)
      end
    end

    context "with no paid on" do
      let(:params) {valid_params.except(:paid_on)}

      xit "should fail validation" do
        expect(PremiumPayment.create(**params).errors[:paid_on].any?).to be_truthy
      end
    end

    context "with no amount" do
      let(:params) {valid_params.except(:amount)}

      xit "should fail validation" do
        expect(PremiumPayment.create(**params).errors[:amount].any?).to be_truthy
      end
    end

    context "with no method kind" do
      let(:params) {valid_params.except(:method_kind)}

      xit "should fail validation" do
        expect(PremiumPayment.create(**params).errors[:method_kind].any?).to be_truthy
      end
    end

    context "with no reference_id" do
      let(:params) {valid_params.except(:reference_id)}

      xit "should fail validation" do
        expect(PremiumPayment.create(**params).errors[:reference_id].any?).to be_truthy
      end
    end

    context "with all valid parameters" do
      let(:params) { valid_params }

      xit "should pass validation" do
        expect(PremiumPayment.new(**params).valid?).to be_truthy
      end
    end
  end

end
