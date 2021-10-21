# frozen_string_literal: true

require "rails_helper"

# module Operations for class CreateDocumentAndNotifyRecipient
module Operations
  RSpec.describe Fdsh::Ridp::CreateEligibilityResponseModel do

    let(:payload) do
      {
        "primary_member_hbx_id": "efa925ec29d4471580210ecefbbf5f7e",
        "event_kind": "primary",
        "metadata": [
          ["content_type", "application/json"],
          ["delivery_mode", 2],
          ["priority", 0],
          ["correlation_id", "efa925ec29d4471580210ecefbbf5f7e"],
          ["expiration", "100000"],
          ["type", "fdsh.eligibilities.ridp"],
          ["app_id", "fdsh_gateway"]
        ],
        "response": {
          "attestations": {
            "ridp_attestation": {
              "is_satisfied": false,
              "is_self_attested": true,
              "satisfied_at": 'null',
              "evidences": [{
                "primary_response": {
                  "Response": {
                    "ResponseMetadata": {
                      "ResponseCode": "HE000050",
                      "ResponseDescriptionText": "Cannot formulate questions for this consumer. Please reference Final Decision Code.",
                      "TDSResponseDescriptionText": 'null'
                    },
                    "VerificationResponse": {
                      "SessionIdentification": "QEJF03OV2IYYOQY5FBXWSQ0M.pidd2v-210714120913412971074",
                      "DSHReferenceNumber": "3227-50-cc0c",
                      "FinalDecisionCode": "RF4",
                      "VerificationQuestions": {}
                    }
                  }
                }
              }],
              "status": "in_progress"
            }
          }
        }
      }
    end

    subject do
      described_class.new.call(payload.to_json)
    end

    it "should pass" do
      expect(subject).to be_success
    end
  end

  RSpec.describe Fdsh::Ridp::CreateEligibilityResponseModel do

    let(:payload) do
      {
        "primary_member_hbx_id": "87171b1921034e6399b15ff27c3e2b94",
        "event_kind": "secondary",
        "metadata": [
          ["content_type", "application/json"],
          ["delivery_mode", 2],
          ["priority", 0],
          ["correlation_id", "87171b1921034e6399b15ff27c3e2b94"],
          ["expiration", "100000"],
          ["timestamp", "2059-01-03T15:44:01.000-05:00"],
          ["type", "fdsh.eligibilities.ridp"],
          ["app_id", "fdsh_gateway"]
        ],
        "response": {
          "attestations": {
            "ridp_attestation": {
              "is_satisfied": true,
              "is_self_attested": true,
              "satisfied_at": "2021-07-14T19:48:10.127-04:00",
              "evidences": [{
                "secondary_response": {
                  "Response": {
                    "ResponseMetadata": {
                      "ResponseCode": "HS000000",
                      "ResponseDescriptionText": "Successful",
                      "TDSResponseDescriptionText": nil
                    },
                    "VerificationResponse": {
                      "FinalDecisionCode": "ACC",
                      "DSHReferenceNumber": "481c-0e-520c",
                      "SessionIdentification": "UJANBKK16UBOZP2V5PNHJBMT.pidd1v-210714184544346087955"
                    }
                  }
                }
              }],
              "status": "success"
            }
          }
        }
      }
    end

    subject do
      described_class.new.call(payload.to_json)
    end

    it "should pass" do
      expect(subject).to be_success
    end
  end
end
