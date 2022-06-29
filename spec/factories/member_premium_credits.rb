# frozen_string_literal: true

FactoryBot.define do
  factory :member_premium_credit, class: '::MemberPremiumCredit' do
    association :group_premium_credit

    kind     { 'aptc_eligible' }
    value    { 'true' }
    start_on { TimeKeeper.date_of_record.beginning_of_month }

    trait :aptc_ineligible do
      kind  { 'aptc_eligible' }
      value { 'false' }
    end

    trait :csr_eligible do
      kind  { 'csr' }
      value { '87' }
    end

    trait :csr_ineligible do
      kind  { 'csr' }
      value { '0' }
    end
  end
end

