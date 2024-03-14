# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ::Operations::Transformers::InteractiveVerificationTo::Attestation do
  describe "#call" do
    subject { described_class.new.call(interactive_verification) }

    let(:verification_params) do
      {
        session_id: "abcde",
        transaction_id: "abcdef",
        questions_attributes: {
          "0" => {
            "question_id" => "1",
            "question_text" => "some text here",
            "response_id" => "234566",
            "responses_attributes" => {
              "0" => {
                "response_text" => "r_text",
                "response_id" => "r_id"
              }
            }
          }
        }
      }
    end

    let(:interactive_verification) do
      ::IdentityVerification::InteractiveVerification.new(verification_params)
    end

    context "when interactive verification passed" do
      it "should construct attestation payload" do
        payload = subject.success
        ridp_attestation = payload.dig(:attestations, :ridp_attestation)

        expect(ridp_attestation).to include(
          is_satisfied: false,
          is_self_attested: true,
          satisfied_at: nil,
          status: "in_progress"
        )
        expect(ridp_attestation).to include(:evidences)
      end

      it "should construct secondary request with reference number and session identification" do
        payload = subject.success
        ridp_attestation = payload.dig(:attestations, :ridp_attestation)

        secondary_request =
          ridp_attestation.dig(:evidences, 0, :secondary_request)

        expect(secondary_request).to include(
          SessionIdentification: "abcde",
          DSHReferenceNumber: "abcdef"
        )

        verification_answer =
          secondary_request.dig(:VerificationAnswerSet, :VerificationAnswers, 0)

        expect(verification_answer).to include(
          VerificationQuestionNumber: 1,
          VerificatonAnswer: 234_566
        )
      end
    end
  end
end
