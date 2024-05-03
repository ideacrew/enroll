# frozen_string_literal: true

require 'rails_helper'

describe Validators::ControllerParameters::ProductsQhpParameters::SummaryHbxEnrollmentContract, "given a valid BSON ID" do
  let(:hbx_enrollment_id) { BSON::ObjectId.new.to_s}

  let(:value) { { hbx_enrollment_id: hbx_enrollment_id } }

  subject { described_class.new.call(value) }

  it "is valid" do
    expect(subject.success?).to be_truthy
  end

  it "returns the value" do
    expect(subject.values[:hbx_enrollment_id]).to eq hbx_enrollment_id
  end
end

describe Validators::ControllerParameters::ProductsQhpParameters::SummaryHbxEnrollmentContract, "given nothing" do

  let(:value) { { hbx_enrollment_id: nil } }

  subject { described_class.new.call(value) }

  it "is valid" do
    expect(subject.success?).to be_truthy
  end

  it "returns the value" do
    expect(subject.values[:hbx_enrollment_id]).to eq nil
  end
end

describe Validators::ControllerParameters::ProductsQhpParameters::SummaryHbxEnrollmentContract, "given some letters" do

  let(:value) { { hbx_enrollment_id: "abcdefg2020" } }

  subject { described_class.new.call(value) }

  it "is invalid" do
    expect(subject.success?).to be_falsey
  end
end

describe Validators::ControllerParameters::ProductsQhpParameters::SummaryHbxEnrollmentContract, "given some javascript" do

  let(:value) { { hbx_enrollment_id: "<script>something</script>" } }

  subject { described_class.new.call(value) }

  it "is invalid" do
    expect(subject.success?).to be_falsey
  end
end