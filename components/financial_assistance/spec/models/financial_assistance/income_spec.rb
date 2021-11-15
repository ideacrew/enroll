# frozen_string_literal: true

require 'rails_helper'

RSpec.describe FinancialAssistance::Income, type: :model, dbclean: :after_each do
  let!(:family_id) { BSON::ObjectId.new }
  let!(:application) { FactoryBot.create(:application, family_id: family_id) }
  let!(:eligibility_determination) { FactoryBot.create(:financial_assistance_eligibility_determination, application: application) }
  let!(:family_member_id) { BSON::ObjectId.new }
  let!(:applicant) {FactoryBot.create(:applicant, eligibility_determination_id: eligibility_determination.id, application: application, family_member_id: family_member_id)}
  let!(:income) do
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

  context 'constants' do
    let(:earned_incomes) { ['wages_and_salaries', 'net_self_employment', 'scholarship_payments'] }
    let(:unearned_incomes) do
      %w[alimony_and_maintenance
         american_indian_and_alaskan_native
         capital_gains
         dividend
         employer_funded_disability
         estate_trust
         farming_and_fishing
         foreign
         interest
         lump_sum_amount
         military
         other
         pension_retirement_benefits
         permanent_workers_compensation
         prizes_and_awards
         rental_and_royalty
         social_security_benefit
         supplemental_security_income
         tax_exempt_interest
         unemployment_income
         income_from_irs]
    end

    it 'should return expected result for earned incomes' do
      expect(::FinancialAssistance::Income::EARNED_INCOME_KINDS).to eq(earned_incomes)
    end

    it 'should return expected result for unearned incomes' do
      expect(::FinancialAssistance::Income::UNEARNED_INCOME_KINDS).to eq(unearned_incomes)
    end
  end

  context 'hours_worked_per_week' do
    context 'end_on is before TimeKeeper.date_of_record' do
      before do
        income.update_attributes!({ start_on: TimeKeeper.date_of_record.prev_year,
                                    end_on: (TimeKeeper.date_of_record - 2.days)})
      end

      it 'should return 0' do
        expect(income.hours_worked_per_week).to be_zero
      end
    end
  end

  # describe 'dup_instance' do
  #   context 'where income has both employer_address and employer_phone' do
  #   end

  #   context 'where income does not have both employer_address and employer_phone' do
  #   end
  # end
end
