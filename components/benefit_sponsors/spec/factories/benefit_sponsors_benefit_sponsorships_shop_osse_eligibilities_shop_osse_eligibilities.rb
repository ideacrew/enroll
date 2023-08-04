# frozen_string_literal: true

FactoryBot.define do
  factory :benefit_sponsors_shop_osse_eligibility,
          class:
            'BenefitSponsors::BenefitSponsorships::ShopOsseEligibilities::ShopOsseEligibility' do

    key { :shop_osse_eligibility }
    title { 'Contribution Subsidy' }
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
        :shop_osse_eligibilities_shop_osse_grant,
        key: :contribution_subsidy_grant,
        title: 'Contribution Subsidy Grant'
      )
      eligibility.current_state = eligibility.latest_state_history.to_state
    end

    trait :with_admin_attested_evidence do
      after :build do |eligibility, evaluator|
        eligibility.evidences << FactoryBot.build(
          :shop_osse_eligibilities_admin_attested_evidence,
          to_state: evaluator.evidence_state,
          is_eligible: evaluator.is_eligible,
          effective_on: evaluator.effective_on
        )
      end
    end
  end
end
