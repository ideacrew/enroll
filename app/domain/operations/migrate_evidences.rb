# frozen_string_literal: true

require 'dry/monads'
require 'dry/monads/do'

module Operations
  # Operation to migrate ols evidences to new evidences model
  class MigrateEvidences
    include Dry::Monads[:do, :result]

    def call(applicant:)
      valid_applicant = yield validate_applicant(applicant)
      migrate_evidences(valid_applicant)
    end

    private

    def validate_applicant(applicant)
      if applicant.is_a?(::FinancialAssistance::Applicant)
        Success(applicant)
      else
        Failure("Invalid applicant object #{applicant}, expected FinancialAssistance::Applicant")
      end
    end

    def evidence_name(evidence)
      {
        'aces_mec' => "build_local_mec_evidence",
        'esi_mec' => "build_esi_evidence",
        'non_esi_mec' => "build_non_esi_evidence",
        'income' => "build_income_evidence"
      }[evidence.key.to_s]
    end

    def create_new_evidence(applicant, evidence)
      key = evidence.key.to_s == "aces_mec" ? "local_mec" : evidence.key.to_s
      title = evidence.title == "ACES MEC" ? "Local MEC" : evidence.title
      applicant.send(evidence_name(evidence),
                     key: key.to_sym,
                     title: title,
                     aasm_state: evidence.eligibility_status,
                     is_satisfied: evidence.type_verified?,
                     verification_outstanding: evidence.type_unverified?,
                     created_at: evidence.created_at,
                     updated_at: evidence.updated_at,
                     due_on: evidence.due_on)
    end

    def build_verification_histories(evidence)
      evidence.verification_history.collect do |history|
        ::Eligibilities::VerificationHistory.new(action: history.action,
                                                 updated_by: history.modifier,
                                                 update_reason: history.update_reason,
                                                 created_at: history.created_at,
                                                 updated_at: history.updated_at)
      end
    end

    def build_request_results(evidence)
      evidence.eligibility_results.collect do |eligibility_result|
        params = eligibility_result.serializable_hash
        ::Eligibilities::RequestResult.new(params)
      end
    end

    def build_documents(evidence)
      evidence.documents.collect do |document|
        params = document.serializable_hash
        ::Document.new(params)
      end
    end

    def migrate_evidences(applicant)
      applicant.evidences.each do |evidence|
        next unless evidence.key.present?
        new_evidence = create_new_evidence(applicant, evidence)
        next unless new_evidence.present?
        verification_histories = build_verification_histories(evidence)
        new_evidence.verification_histories = verification_histories if verification_histories.present?
        request_results = build_request_results(evidence)
        new_evidence.request_results = request_results if request_results.present?
        documents = build_documents(evidence)
        new_evidence.documents = documents if documents.present?
      end

      if applicant.valid?
        Success(applicant.save!)
      else
        Failure("Error: unable to migrate #{evidence.key} evidences for applicant: #{applicant.id} due to #{applicant.errors.to_h}")
      end
    rescue StandardError => e
      Failure("Error: unable to migrate Evidences for applicant: #{applicant.id} due to #{e.inspect}")
    end
  end
end
