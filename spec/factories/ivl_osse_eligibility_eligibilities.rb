# frozen_string_literal: true

FactoryBot.define do
  factory :ivl_osse_eligibility, class: '::IvlOsseEligibility::Eligibility' do

    title { 'Contribution Subsidy' }
    description { 'Osse Contribution Subsidy' }

    transient do
      from_state { :draft }
      to_state { :eligible }
      is_eligible { true }
      effective_on { TimeKeeper.date_of_record.beginning_of_month }
    end

    trait :with_state_history do
      after :build do |eligibility, evaluator|
        eligibility.state_histories << FactoryBot.build(
          :eligible_state_history,
          from_state: evaluator.from_state,
          to_state: evaluator.to_state,
          is_eligible: evaluator.is_eligible,
          effective_on: evaluator.effective_on
        )
      end
    end
  end
end