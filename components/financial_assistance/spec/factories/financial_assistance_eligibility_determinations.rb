# frozen_string_literal: true

FactoryBot.define do
  factory :financial_assistance_eligibility_determination, class: 'FinancialAssistance::EligibilityDetermination' do

    association :application

    determined_at { TimeKeeper.datetime_of_record }
    max_aptc  { 225.13 }
    csr_percent_as_integer { 87 }
    source { 'Faa' }
    effective_starting_on { TimeKeeper.date_of_record.beginning_of_year }
  end
end