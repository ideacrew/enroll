require "rails_helper"

RSpec.describe "insured/consumer_roles/immigration_document_options.js.erb" do
  let(:person) {FactoryBot.build(:person)}
  let(:consumer_role) {FactoryBot.build(:consumer_role)}

  context "with target" do
    before :each do
      allow(person).to receive(:consumer_role).and_return consumer_role
      assign(:target, person)
      assign(:vlp_doc_target, "naturalization_cert_container")
      render template: "insured/consumer_roles/immigration_document_options.js.erb"
    end

    it "should have form_for" do
      expect(rendered).to match /form/
      expect(rendered).to match /naturalization_cert_container/
    end
  end

  context "without target" do
    before :each do
      assign(:target, nil)
      assign(:vlp_doc_target, "naturalization_cert_container")
      render template: "insured/consumer_roles/immigration_document_options.js.erb"
    end

    it "should not have form_for" do
      expect(rendered).not_to match /form/
    end
  end
end
