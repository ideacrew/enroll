require 'rails_helper'

describe Parsers::ResidencyVerificationResponse do

  let(:xml) {File.read(Rails.root.join("spec","test_data", "residency_verification_payloads", "response.xml"))}
  let(:subject) {Parsers::ResidencyVerificationResponse.new}
  it 'returns hash' do
    subject.parse(xml)
    expect(subject.to_hash).to eq({:residency_verification_response=>"ADDRESS_NOT_IN_AREA"})
  end
end