require 'rails_helper'
require 'active_support/time'

describe FinancialStatement do

  TEN_DOLLARS = 1000

  before(:all) do

    @financial_statement = FinancialStatement.new

    alternate_benefit = AlternateBenefit.new
    alternate_benefit.start_date = Date.new(2011, 01, 01)
    alternate_benefit.end_date = Date.new(2015, 03, 03)

    alternate_benefit2 = AlternateBenefit.new
    alternate_benefit2.start_date = Date.new(2013, 01, 01)
    alternate_benefit2.end_date =  Date.new(2013, 03, 03)


    deduction1 = Deduction.new
    deduction1.amount_in_cents = 470
    deduction1.start_date = Date.new(2013, 01, 01)
    deduction1.end_date = nil
    deduction1.frequency = "yearly"


    income1 = Income.new
    income1.amount_in_cents = 111400
    income1.start_date = Date.new(2012, 04, 12)
    income1.end_date = nil
    income1.frequency = "monthly"

    income2 = Income.new
    income2.amount_in_cents = 120030
    income2.start_date = Date.new(2013, 10, 02)
    income2.end_date = nil
    income2.frequency = "monthly"

    income3 = Income.new
    income3.amount_in_cents = 111400
    income3.start_date = nil
    income3.end_date = nil
    income3.frequency = "monthly"

    income4 = Income.new
    income4.amount_in_cents = 120030
    income4.start_date = nil
    income4.end_date = nil
    income4.frequency = "monthly"

    @income5 = income1

    @financial_statement.incomes << income1 << income2 << income3 << income4

    @financial_statement.deductions << deduction1

    @financial_statement.alternate_benefits << alternate_benefit << alternate_benefit2


end

  context "yearwise income computation" do

    it "should compute the income correctly with end_date as nil" do

      financial_statement = FinancialStatement.new
      income1 = Income.new
      income1.amount_in_cents = 111400
      income1.start_date = Date.new(2012, 04, 12)
      income1.end_date = nil
      income1.frequency = "monthly"

      financial_statement.incomes << income1

      income_hash = financial_statement.compute_yearwise(financial_statement.incomes)

      expect(((income_hash[2014]) - 1336800).abs).to be < TEN_DOLLARS

    end

    it "should compute prorated income" do

      financial_statement = FinancialStatement.new
      income1 = Income.new
      income1.amount_in_cents = 10000
      income1.start_date = Date.new(2012, 01, 15)
      income1.end_date = Date.new(2012, 02, 14)
      income1.frequency = "monthly"

      financial_statement.incomes << income1

      income_hash = financial_statement.compute_yearwise(financial_statement.incomes)

      expect(((income_hash[2012]) - 10000).abs).to be < TEN_DOLLARS

    end

    it "should compute the income hash" do

      financial_statement = FinancialStatement.new
      income1 = Income.new
      income1.amount_in_cents = 100000
      income1.start_date = Date.new(2012, 01, 01)
      income1.end_date = Date.new(2014, 01, 30)
      income1.frequency = "monthly"

      income2 = Income.new
      income2.amount_in_cents = 1000000
      income2.start_date = Date.new(2014, 01, 01)
      income2.end_date = nil
      income2.frequency = "yearly"

      financial_statement.incomes << income1 << income2

      income_hash = financial_statement.compute_yearwise(financial_statement.incomes)

      expect(((income_hash[2014]) - (96923 + 1000000)).abs).to be < TEN_DOLLARS
    end
  end

  context "yearwise deductions computation" do

    it "should compute the deductions hash" do

      deduction_hash = @financial_statement.compute_yearwise(@financial_statement.deductions)

      expect(((deduction_hash[2014]) - 470).abs).to be < TEN_DOLLARS
    end
  end

  it "should check for benifits in current year" do

    expect(@financial_statement.is_receiving_benefit?).to be_true
  end

end