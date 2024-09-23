# frozen_string_literal: true

require 'dry/monads'
require 'dry/monads/do'

module Operations
  module Fdsh
    module Ridp
      # This class will persist ridp responce to DB
      class PrimaryResponseToInteractiveVerification
        include Dry::Monads[:do, :result, :try]

        def call(params)
          evidence = yield fetch_evidence(params)
          q_set = yield fetch_questions_set(evidence)
          payload = yield construct_interactive_verifications_params(evidence, q_set)
          interactive_verification = yield to_model(payload)

          Success(interactive_verification)
        end

        private

        def fetch_evidence(response)
          evidence = response.dig(:attestations, :ridp_attestation, :evidences, 0)
          evidence.present? ? Success(evidence) : Failure("No Evidence Present")
        end

        def fetch_questions_set(evidence)
          question_set = evidence.dig(:primary_response, :Response, :VerificationResponse, :VerificationQuestions, :VerificationQuestionSet)
          question_set.present? ? Success(question_set) : Failure("No questions present")
        end

        def construct_interactive_verifications_params(evidence, q_set)
          session_id = evidence.dig(:primary_response, :Response, :VerificationResponse, :SessionIdentification)
          transaction_id = evidence.dig(:primary_response, :Response, :VerificationResponse, :DSHReferenceNumber)
          question_attributes = {}
          q_set.each_with_index do |q, idx|
            response_attributes = {}
            q[:VerificationAnswerChoiceText].each_with_index do |ro, r_idx|
              response_attributes[r_idx + 1] = {
                response_id: r_idx + 1,
                response_text: ro
              }
              question_attributes[(idx + 1).to_s] = {
                question_id: idx + 1,
                question_text: q[:VerificationQuestionText],
                responses_attributes: response_attributes
              }
            end
          end

          Success({session_id: session_id, transaction_id: transaction_id, questions_attributes: question_attributes})
        end

        def to_model(payload)
          Try do
            ::IdentityVerification::InteractiveVerification.new(payload)
          end
        end
      end
    end
  end
end
