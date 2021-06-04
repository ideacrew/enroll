# frozen_string_literal: true

require 'rails_helper'

RSpec.describe FinancialAssistance::Operations::Applicant::CalculateAndPersistNetAnnualIncome, dbclean: :after_each do

  let(:family_id)    { BSON::ObjectId.new }
  let!(:application) { FactoryBot.create(:financial_assistance_application, family_id: family_id, aasm_state: "draft") }
  let(:applicant) do
    FactoryBot.create(:financial_assistance_applicant,
                      application: application,
                      ssn: '889984400',
                      dob: Date.new(1993,12,9),
                      first_name: 'james',
                      last_name: 'bond')
  end

  let(:income) do
    FactoryBot.build(:financial_assistance_income, amount: 200, frequency_kind: "biweekly")
  end

  let(:deduction) do
    FactoryBot.build(:financial_assistance_deduction, amount: 100, frequency_kind: "biweekly")
  end

  describe "passing empty params" do
    let(:params) { {  }}

    it "fails" do
      result = subject.call(params)
      expect(result).not_to be_success
      expect(result.failure).to eq "Invalid applicant"
    end
  end

  describe "passing invalid object in params" do
    let(:params) { { applicant: application }}

    it "fails" do
      result = subject.call(params)
      expect(result).not_to be_success
      expect(result.failure).to eq "Invalid applicant"
    end
  end

  describe "passing valid params" do
    let(:params) do
      {applicant: applicant}
    end

    before do
      applicant.incomes << income
      applicant.deductions << deduction
    end

    it 'should pass, calculate and persist net annual income on applicant' do
      result = subject.call(params)
      expect(result.success).to eq applicant
      expect(applicant.net_annual_income.to_f).to eq 2600.00
    end
  end
end