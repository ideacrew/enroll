FactoryGirl.define do
  factory :financial_assistance_income, class: 'FinancialAssistance::Income' do

    association :applicant

    title 'Test Income'
    amount 10
    frequency_kind 'monthly'
    start_on (TimeKeeper.date_of_record.beginning_of_month)
    end_on (TimeKeeper.date_of_record.end_of_month)
  end
end