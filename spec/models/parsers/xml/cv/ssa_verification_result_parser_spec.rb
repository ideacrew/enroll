require 'rails_helper'

describe Parsers::Xml::Cv::SsaVerificationResultParser do

  let(:xml) {File.read(Rails.root.join("spec","test_data", "ssa_verification_payloads", "response.xml"))}
  let(:subject) {Parsers::Xml::Cv::SsaVerificationResultParser.parse(xml)}
  it 'returns hash' do
    puts subject.to_hash
    expect(subject.to_hash.flatten).to include(:ssn_verified, :incarcerated, :individual)
  end

end