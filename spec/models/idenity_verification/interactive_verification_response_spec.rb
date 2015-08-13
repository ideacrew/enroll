require "rails_helper"

describe IdentityVerification::InteractiveVerificationResponse do
  let(:response_data) { File.read(file_path) }
  subject {
    IdentityVerification::InteractiveVerificationResponse.parse(response_data, :single => true)
  }

  describe "given a failed response" do
    let(:file_path) { File.join(Rails.root, "spec", "test_data", "ridp_payloads", "failed_start_response.xml") }
    let(:expected_response_text) { "Failed response - please see ref below."}
    let(:expected_transaction_id) { "WhateverRefNumberHere" }

    it "should be considered failed" do
      puts subject.verification_result.response_code
      expect(subject.failed?).to eq true
    end

    it "should have the correct response text" do
      expect(subject.response_text).to eq expected_response_text
    end

    it "should have the correct transaction_id" do
      expect(subject.transaction_id).to eq expected_transaction_id
    end
  end
end
