require 'rails_helper'

describe Parsers::Xml::Cv::SsaVerificationResultParser do

  let(:xml) { File.read(Rails.root.join("spec", "test_data", "ssa_verification_payloads", "response.xml")) }
  let(:xml2) { File.read(Rails.root.join("spec", "test_data", "ssa_verification_payloads", "response2.xml")) }

  context "ssn_verified=true" do
    let(:subject) { Parsers::Xml::Cv::SsaVerificationResultParser.parse(xml) }
    it 'returns hash' do
      expect(subject.to_hash).to include(:ssn_verified, :individual, :response_code)
      expect(subject.to_hash[:ssn_verified]).to eq("true")
    end
  end

  context "ssn_verification_failed=true" do
    let(:subject) { Parsers::Xml::Cv::SsaVerificationResultParser.parse(xml2) }
    it 'returns hash' do
      expect(subject.to_hash).to include(:ssn_verification_failed, :individual, :response_code)
      expect(subject.to_hash[:ssn_verification_failed]).to eq("true")
    end
  end
end
