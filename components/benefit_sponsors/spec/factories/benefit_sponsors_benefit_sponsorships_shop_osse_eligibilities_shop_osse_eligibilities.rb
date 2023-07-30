# frozen_string_literal: true

FactoryBot.define do
  factory :benefit_sponsors_benefit_sponsorships_shop_osse_eligibilities_shop_osse_eligibility,
          class:
            'BenefitSponsors::BenefitSponsorships::ShopOsseEligibilities::ShopOsseEligibility' do

    key { :shop_osse_eligibility }
    title { 'Contribution Subsidy' }
    description { 'Osse Contribution Subsidy' }

    transient do
      from_state { :initial }
      to_state { :initial }
      is_eligible { false }
      effective_on { TimeKeeper.date_of_record.beginning_of_month }
    end

    after :build do |eligibility, evaluator|
      eligibile_to_state = :published unless evaluator.to_state == :initial
      eligibility.state_histories << FactoryBot.build(
        :eligible_state_history,
        from_state: evaluator.from_state,
        to_state: eligibile_to_state,
        is_eligible: evaluator.is_eligible,
        effective_on: evaluator.effective_on
      )

      eligibility.grants << FactoryBot.build(
        :benefit_sponsors_benefit_sponsorship_osse_grant,
        key: :contribution_subsidy_grant,
        title: 'Contribution Subsidy Grant'
      end
    end

    trait :with_evidence do
      after :build do |eligibility, evaluator|
        eligibility.evidences << FactoryBot.build(
          :benefit_sponsors_benefit_sponsorship_osse_admin_attested_evidence,
          from_state: evaluator.from_state,
          to_state: evaluator.to_state,
          is_eligible: evaluator.is_eligible,
          effective_on: evaluator.effective_on
        )
      end
    end
  end
end
