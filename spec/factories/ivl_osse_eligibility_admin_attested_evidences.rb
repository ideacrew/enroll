# frozen_string_literal: true

FactoryBot.define do
  factory :ivl_osse_admin_attested_evidence, class: "::IvlOsseEligibilities::AdminAttestedEvidence" do

    title { 'Ivl Osse Evidence' }
    description { 'Evidence for Individual OSSE Eligibility' }
    key { :shop_osse_evidence }
    is_satisfied { false }
    subject_ref { URI("gid://enroll_app/Consumer_role")}

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
