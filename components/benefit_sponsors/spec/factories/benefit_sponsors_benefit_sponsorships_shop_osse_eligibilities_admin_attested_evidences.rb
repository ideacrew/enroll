# frozen_string_literal: true

FactoryBot.define do
  factory :shop_osse_eligibilities_admin_attested_evidence,
          class:
            'BenefitSponsors::BenefitSponsorships::ShopOsseEligibilities::AdminAttestedEvidence' do

    title { 'Sho Osse Evidence' }
    description { 'Evidence for Group OSSE Eligibility' }
    key { :shop_osse_evidence }
    is_satisfied { false }
    subject_ref { URI("gid://enroll_app/BenefitSponsors/BenefitSponsorship")}
    evidence_ref { URI("gid://enroll_app/BenefitSponsors/Evidence") }

    transient do
      from_state { :initial }
      to_state { :initial }
      is_eligible { false }
      effective_on { TimeKeeper.date_of_record.beginning_of_month }
    end

    after :build do |evidence, evaluator|
      evidence.state_histories << FactoryBot.build(
        :eligible_state_history,
        from_state: evaluator.from_state,
        to_state: evaluator.to_state,
        is_eligible: evaluator.is_eligible,
        event: "move_to_#{evaluator.to_state}".to_sym,
        effective_on: evaluator.effective_on
      )

      evidence.current_state = evidence.latest_state_history.to_state
      evidence.is_satisfied = true if evaluator.is_eligible
    end
  end
end
