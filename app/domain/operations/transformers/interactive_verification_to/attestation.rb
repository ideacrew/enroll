# frozen_string_literal: true

require 'dry/monads'
require 'dry/monads/do'
require 'aca_entities/magi_medicaid/libraries/iap_library'

module Operations
  module Transformers
    module InteractiveVerificationTo
      # Interactive_verification params to be transformed.
      class Attestation
        # constructs cv3 payload for fdsh gateway.

        include Dry::Monads[:result, :do]
        include Acapi::Notifiers
        require 'securerandom'

        def call(interactive_verification)
          construct_payload(interactive_verification)
        end

        private

        def construct_payload(interactive_verification)
          payload = {
            attestations: {
              ridp_attestation: construct_ridp_attestation_hash(interactive_verification)
            }
          }

          Success(payload)
        end

        def construct_ridp_attestation_hash(interactive_verification)
          secondary_request = construct_secondary_request(interactive_verification)
          secondary_request[:secondary_request][:DSHReferenceNumber] = interactive_verification.transaction_id if EnrollRegistry[:ridp_h139].setting(:payload_format).item == "json"
          {
            is_satisfied: false,
            is_self_attested: true,
            satisfied_at: nil,
            status: 'in_progress',
            evidences: [secondary_request]
          }
        end

        def construct_secondary_request(interactive_verification)
          {
            secondary_request: {
              SessionIdentification: interactive_verification.session_id,
              VerificationAnswerSet: {
                VerificationAnswers: construct_verification_answers(interactive_verification.questions)
              }
            }
          }
        end

        def construct_verification_answers(questions)
          questions.collect do |question|
            {
              VerificationQuestionNumber: question.question_id.to_i,
              VerificatonAnswer: question.response_id.to_i
            }
          end
        end
      end
    end
  end
end
