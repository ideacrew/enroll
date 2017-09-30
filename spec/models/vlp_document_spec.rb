require 'rails_helper'

RSpec.describe VlpDocument, :type => :model do
  let(:person) {FactoryGirl.create(:person, :with_consumer_role)}
  let(:person2) {FactoryGirl.create(:person, :with_consumer_role)}
  let(:family_member_person) { FamilyMember.new(:is_active => true, is_primary_applicant: true, is_consent_applicant: true, person: person) }



  describe "creates person with vlp_docs" do
    it "creates scope for uploaded docs" do
      expect(person.consumer_role.vlp_documents).to exist
    end

    it "returns number of uploaded documents" do
      person2.consumer_role.vlp_documents.first.identifier = "url"
      expect(person2.consumer_role.vlp_documents.uploaded.count).to eq(1)
    end
  end


  describe "VLP documents status" do
    let(:family){
      f = Family.new(:family_members => [family_member_person])
      f.save
      f
    }
    it "verify there vlp_documents_status is nil" do
      expect(family.vlp_documents_status).to eq(nil)
    end

    it "returns vlp_documents_status is partially uploaded when single document is uploaded" do
      p = family.primary_applicant.person
      p.consumer_role.vlp_documents << FactoryGirl.build(:vlp_document)
      p.save!
      p.update_family_document_status!
      expect(p.primary_family.vlp_documents_status).to eq("Partially Uploaded")
    end

    it "returns vlp_documents_status is fully uploaded when all documents are uploaded" do
      p = family.primary_applicant.person
      p.consumer_role.vlp_documents << FactoryGirl.build(:vlp_document, verification_type: "Social Security Number")
      p.save!
      p.update_family_document_status!
      expect(p.primary_family.vlp_documents_status).to eq("Fully Uploaded")
    end
  end
end
