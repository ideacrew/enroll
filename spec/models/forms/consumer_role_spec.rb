require "rails_helper"

describe Forms::ConsumerRole do
  let(:consumer_role) { FactoryBot.build(:consumer_role)}

  subject {
    Forms::ConsumerRole.new(
      consumer_role
    )
  }

  it "should respond to vlp_document_kind and doc_number" do
    expect(subject).to respond_to(:vlp_document_kind, :doc_number)
  end

  it "should return the model name" do
    expect(subject.model_name).to eq Person.model_name
  end

end
