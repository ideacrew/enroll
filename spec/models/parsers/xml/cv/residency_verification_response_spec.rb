require 'rails_helper'

describe Parsers::Xml::Cv::ResidencyVerificationResponse do

  let(:xml) {File.read(Rails.root.join("spec","test_data", "residency_verification_payloads", "response.xml"))}
  let(:subject) { Parsers::Xml::Cv::ResidencyVerificationResponse.new }
  it 'returns hash' do
    subject.parse(xml)
    expect(subject.to_hash).to eq({:residency_verification_response=>"ADDRESS_NOT_IN_AREA"})
  end

  it 'returns the correct response from a class level invocation' do
    value = Parsers::Xml::Cv::ResidencyVerificationResponse.parse(xml).to_hash
    expect(value.to_hash).to eq({:residency_verification_response=>"ADDRESS_NOT_IN_AREA"})
  end
end
