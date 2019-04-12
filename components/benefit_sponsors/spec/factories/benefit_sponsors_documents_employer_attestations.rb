FactoryBot.define do
  factory :benefit_sponsors_documents_employer_attestation, class: 'BenefitSponsors::Documents::EmployerAttestation' do
    aasm_state "unsubmitted"

    trait :with_attestation_document do
      after :create do |employer_attestation, evaluator|
        if employer_attestation.submitted?
          employer_attestation_documents { [FactoryBot.create(:benefit_sponsors_documents_employer_attestation_document, employer_attestation: employer_attestation)] }
        end
      end
    end
  end
end
