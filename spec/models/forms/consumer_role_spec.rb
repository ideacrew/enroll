require "rails_helper"

describe Forms::ConsumerRole do
  let(:consumer_role) { FactoryGirl.build(:consumer_role)}

  subject {
    Forms::ConsumerRole.new(
      consumer_role
    )
  }

  it "should return the list of vlp document kinds" do
    expect(subject.vlp_document_kinds).to eq ::ConsumerRole::VLP_DOCUMENT_KINDS
  end

  it "should return the model name" do
    expect(subject.model_name).to eq Person.model_name
  end

end
