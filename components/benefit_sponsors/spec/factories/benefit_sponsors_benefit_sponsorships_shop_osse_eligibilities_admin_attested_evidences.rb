# frozen_string_literal: true

FactoryBot.define do
  factory :benefit_sponsors_benefit_sponsorships_shop_osse_eligibilities_admin_attested_evidence,
          class:
            'BenefitSponsors::BenefitSponsorships::ShopOsseEligibilities::AdminAttestedEvidence' do

    title { 'Sho Osse Evidence' }
    description { 'Evidence for Group OSSE Eligibility' }
    key { :shop_osse_evidence }
    is_satisfied { false }
    subject_ref { 'shop_osse_evidence'}
    evidence_ref { 'shop_osse_evidence'}

    transient do
      from_state { :draft }
      to_state { :accepted }
      is_eligible { false }
      effective_on { TimeKeeper.date_of_record.beginning_of_month }
    end

    after :build do |evidence, evaluator|
      evidence.state_histories << FactoryBot.build(
        :eligible_state_history,
        from_state: evaluator.from_state,
        to_state: evaluator.to_state,
        is_eligible: evaluator.is_eligible,
        effective_on: evaluator.effective_on
      )

      if evaluator.is_eligible
        evidence.is_satisfied = true
      end
    end
  end
end
