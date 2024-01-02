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
    FactoryBot.build(:financial_assistance_income, amount: 200, start_on: Date.new(TimeKeeper.date_of_record.year,6,1), end_on: Date.new(TimeKeeper.date_of_record.year, 6, 30), frequency_kind: "biweekly")
  end

  let(:deduction) do
    FactoryBot.build(:financial_assistance_deduction, amount: 100, start_on: Date.new(TimeKeeper.date_of_record.year,6,1), end_on: Date.new(TimeKeeper.date_of_record.year, 6, 30), frequency_kind: "biweekly")
  end

  describe "passing empty params" do
    let(:params) { {  }}

    it "fails" do
      result = subject.call(params)
      expect(result).not_to be_success
      expect(result.failure).to eq "Invalid Params"
      expect(applicant.net_annual_income).to eq nil
    end
  end

  describe "passing invalid object in params" do
    let(:params) { { applicant: application }}

    it "fails" do
      result = subject.call(params)
      expect(result).not_to be_success
      expect(result.failure).to eq "Invalid Params"
      expect(applicant.net_annual_income).to eq nil
    end
  end

  describe "passing valid params" do

    context 'Income and deductions have start date and end date present in current year' do
      let(:params) do
        {application_assistance_year: application.assistance_year, applicant: applicant}
      end

      before do
        applicant.incomes << income
        applicant.deductions << deduction
      end

      it 'should pass, calculate and persist net annual income on applicant' do
        result = subject.call(params)
        expect(result.success).to eq applicant
        expect(applicant.net_annual_income.to_f.ceil).to eq 214
      end
    end

    context 'Income and deductions have start date in previous year and no end date and frequency kind is daily' do
      let(:params) do
        {application_assistance_year: application.assistance_year, applicant: applicant}
      end

      let(:income) do
        FactoryBot.build(:financial_assistance_income, start_on: Date.new(2020, 6, 1), end_on: nil,
                                                       amount: 2000, frequency_kind: "monthly")
      end

      let(:deduction) do
        FactoryBot.build(:financial_assistance_deduction, start_on: Date.new(2020, 6, 1), end_on: nil,
                                                          amount: 1000, frequency_kind: "monthly")
      end

      before do
        applicant.incomes << income
        applicant.deductions << deduction
      end

      it 'should pass, calculate and persist net annual income on applicant' do
        result = subject.call(params)
        expect(result.success).to eq applicant
        expect(applicant.net_annual_income.to_f.ceil).to eq 12_000
      end
    end

    context 'Income (no deductions) has start date on 1st of present year and end date on 1st of next year and frequency kind is monthly' do
      let(:params) do
        {application_assistance_year: application.assistance_year, applicant: applicant}
      end

      let(:income) do
        FactoryBot.build(:financial_assistance_income, start_on: Date.new(TimeKeeper.date_of_record.year, 1, 1),
                                                       end_on: Date.new(TimeKeeper.date_of_record.next_year.year, 1, 1),
                                                       amount: 1000, frequency_kind: "monthly")
      end

      before do
        applicant.incomes << income
      end

      it "should calculate net_annual_income correctly" do
        result = subject.call(params)
        expect(result.success).to eq applicant
        expect(applicant.net_annual_income.to_f.ceil).to eq 12_000
      end
    end

    context 'Income (no deductions) has start date on 1st of present year and end date less than assistance year end date' do
      let(:params) do
        {application_assistance_year: application.assistance_year, applicant: applicant}
      end

      let(:income) do
        FactoryBot.build(:financial_assistance_income, start_on: Date.new(TimeKeeper.date_of_record.year, 1, 1),
                                                       end_on: Date.new(TimeKeeper.date_of_record.year, 8, 1),
                                                       amount: 1000, frequency_kind: "monthly")
      end

      before do
        applicant.incomes << income
      end

      it "should calculate net_annual_income correctly in non-leap year" do
        unless Date.gregorian_leap?(application.assistance_year)
          result = subject.call(params)
          expect(result.success).to eq applicant
          expect(applicant.net_annual_income.to_f.ceil).to eq 7_003
        end
      end

    it "should calculate net_annual_income correctly in a leap year" do
      if Date.gregorian_leap?(application.assistance_year)
        result = subject.call(params)
        expect(result.success).to eq applicant
        expect(applicant.net_annual_income.to_f.ceil).to eq 7_017
      end
    end
  end

    context 'Income and deductions have start date in future year and end date in future year and frequency kind is daily' do
      let(:params) do
        {application_assistance_year: application.assistance_year, applicant: applicant}
      end

      let(:income) do
        FactoryBot.build(:financial_assistance_income, start_on: Date.new(TimeKeeper.date_of_record.next_year.year, 6, 1), end_on: nil,
                                                       amount: 2000, frequency_kind: "monthly")
      end

      let(:deduction) do
        FactoryBot.build(:financial_assistance_deduction, start_on: Date.new(TimeKeeper.date_of_record.next_year.year, 6, 1), end_on: nil,
                                                          amount: 1000, frequency_kind: "monthly")
      end

      before do
        applicant.incomes << income
        applicant.deductions << deduction
      end

      it 'should pass, and store 0 net income on applicant' do
        result = subject.call(params)

        expect(result.success).to eq applicant
        expect(applicant.net_annual_income.to_f).to eq 0.0
      end
    end
  end
end
