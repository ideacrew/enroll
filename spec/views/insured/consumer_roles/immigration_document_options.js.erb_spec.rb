require "rails_helper"

RSpec.describe "insured/consumer_roles/immigration_document_options.js.erb" do
  let(:person) {FactoryGirl.build(:person)}
  let(:consumer_role) {FactoryGirl.build(:consumer_role)}
  before :each do
    allow(person).to receive(:consumer_role).and_return consumer_role
    assign(:target, person)
    assign(:vlp_doc_target, "naturalization_cert_container")
    render file: "insured/consumer_roles/immigration_document_options.js.erb"
  end

  it "should have form_for" do
    expect(rendered).to match /form/
    expect(rendered).to match /naturalization_cert_container/
  end
end
