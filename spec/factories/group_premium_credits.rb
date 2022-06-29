# frozen_string_literal: true

FactoryBot.define do
  factory :group_premium_credit, class: '::GroupPremiumCredit' do
    association :family

    kind  { 'aptc_csr' }
    premium_credit_monthly_cap { '300.00' }
    start_on { TimeKeeper.date_of_record.beginning_of_month }
  end
end

