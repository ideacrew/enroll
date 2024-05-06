# frozen_string_literal: true

require 'rails_helper'

describe Validators::ControllerParameters::ProductsQhpParameters::SummaryActiveYearContract, "given a valid four year value" do

  let(:value) { { active_year: "2020" } }

  subject { described_class.new.call(value) }

  it "is valid" do
    expect(subject.success?).to be_truthy
  end

  it "returns the value" do
    expect(subject.values[:active_year]).to eq "2020"
  end
end

describe Validators::ControllerParameters::ProductsQhpParameters::SummaryActiveYearContract, "given some letters" do

  let(:value) { { active_year: "abcdefg2020" } }

  subject { described_class.new.call(value) }

  it "is invalid" do
    expect(subject.success?).to be_falsey
  end
end

describe Validators::ControllerParameters::ProductsQhpParameters::SummaryActiveYearContract, "given some javascript" do

  let(:value) { { active_year: "<script>something</script>" } }

  subject { described_class.new.call(value) }

  it "is invalid" do
    expect(subject.success?).to be_falsey
  end
end