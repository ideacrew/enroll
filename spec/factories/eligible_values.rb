# frozen_string_literal: true

FactoryBot.define do
  factory :eligible_value, class: 'Eligible::Value' do
    title { 'Contribution Subsidy' }
    description { 'Osse Contribution Subsidy' }
    key { :osse_subsidy }
  end
end
