require 'rails_helper'

RSpec.describe RidpDocument, :type => :model do
  let(:person) {FactoryBot.create(:person, :with_consumer_role)}
  let(:person2) {FactoryBot.create(:person, :with_consumer_role)}


  describe "creates person with ridp_docs" do
    it "creates scope for uploaded docs" do
      expect(person.consumer_role.ridp_documents).to exist
    end

    it "returns number of uploaded documents" do
      person2.consumer_role.ridp_documents.first.identifier = "url"
      expect(person2.consumer_role.ridp_documents.uploaded.count).to eq(1)
    end
  end

  context "verification reasons" do
    if EnrollRegistry[:enroll_app].setting(:site_key).item == :me
      it "should have crm document system as verification reason" do
        expect(VlpDocument::VERIFICATION_REASONS).to include("Self-Attestation")
      end
    end
    if EnrollRegistry[:enroll_app].setting(:site_key).item == :dc
      it "should have salesforce as verification reason" do
        expect(VlpDocument::VERIFICATION_REASONS).to include("Self-Attestation")
      end
    end
  end
end
