require "rails_helper"

describe QleKinds::CreateParamsValidator do

  subject { QleKinds::CreateParamsValidator.new }

  let(:valid_params) do
    {
      "title" => "a Title",
      "market_kind" => "fehb",
      "is_self_attested" => "Yes"
    }
  end

  it "is valid" do
    expect(subject.call(valid_params).success?).to be_truthy
  end
end