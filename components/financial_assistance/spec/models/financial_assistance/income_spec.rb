# frozen_string_literal: true

require 'rails_helper'

RSpec.describe FinancialAssistance::Income, type: :model, dbclean: :after_each do
  let(:family_id) { BSON::ObjectId.new }
  let(:application) { FactoryBot.create(:application, family_id: family_id) }
  let!(:eligibility_determination) { FactoryBot.create(:financial_assistance_eligibility_determination, application: application) }
  let(:family_member_id) { BSON::ObjectId.new }
  let(:applicant) {FactoryBot.create(:applicant, eligibility_determination_id: eligibility_determination.id, application: application, family_member_id: family_member_id)}
  let(:income) do
    income = FinancialAssistance::Income.new(valid_params)
    applicant.incomes << income
    income
  end

  let(:valid_params) do
    {
      title: 'Financial Income',
      kind: 'net_self_employment',
      amount: 100,
      start_on: Date.today,
      frequency_kind: 'biweekly'
    }
  end

  context 'valid income' do
    it 'should save income step_1 and submit' do
      expect(income.valid?(:step_1)).to be_truthy
      expect(income.valid?(:submission)).to be_truthy
    end
  end

  context 'Invalid income amount' do
    it 'should save income step_1 and submit' do
      income.update_attributes(kind: 'income_from_irs', amount: -200)
      expect(income.valid?(:step_1)).to be_falsey
      expect(income.valid?(:submission)).to be_falsey
    end
  end
end
