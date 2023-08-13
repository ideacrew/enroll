# frozen_string_literal: true

FactoryBot.define do
  factory :ivl_osse_eligibility, class: 'IvlOsseEligibilities::IvlOsseEligibility' do

    key { "aca_ivl_osse_eligibility_#{TimeKeeper.date_of_record}".to_sym }
    title { 'IVL Osse Subsidy' }
    description { 'Osse Contribution Subsidy' }

    transient do
      from_state { :initial }
      evidence_state { :initial }
      is_eligible { false }
      effective_on { TimeKeeper.date_of_record.beginning_of_month }
    end

    after :build do |eligibility, evaluator|
      eligibility_state = :published unless evaluator.evidence_state == :initial
      eligibility.state_histories << FactoryBot.build(
        :eligible_state_history,
        from_state: evaluator.from_state,
        to_state: eligibility_state || :initial,
        is_eligible: evaluator.is_eligible,
        event: "move_to_#{eligibility_state}".to_sym,
        effective_on: evaluator.effective_on
      )

      eligibility.grants << FactoryBot.build(
        :ivl_osse_eligibility_grant,
        key: :childcare_subsidy_grant,
        title: 'Childcare Subsidy Grant'
      )
      eligibility.current_state = eligibility.latest_state_history.to_state
    end

    trait :with_admin_attested_evidence do
      after :build do |eligibility, evaluator|
        eligibility.evidences << FactoryBot.build(
          :ivl_osse_admin_attested_evidence,
          to_state: evaluator.evidence_state,
          is_eligible: evaluator.is_eligible,
          effective_on: evaluator.effective_on
        )
      end
    end
  end
end
