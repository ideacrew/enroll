require 'rails_helper'

describe ResidencyVerificationResponse do
  let(:params) {
    {
      address_verification: "NOT IN AREA"
    }
  }
  let(:subject) { ResidencyVerificationResponse.new(params) }

  it "should be valid record" do
    expect(subject.valid?).to eq true
  end
  
  it "should have address_verification attribute" do
    expect(subject.attributes.include?("address_verification")).to be_truthy
  end
end
