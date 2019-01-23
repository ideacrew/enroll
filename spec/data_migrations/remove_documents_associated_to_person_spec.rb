require "rails_helper"
require File.join(Rails.root, "app", "data_migrations", "remove_documents_associated_to_person")

describe RemoveDocumentsAssociatedToPerson, dbclean: :after_each do
  let(:given_task_name) { "remove_documents_associated_to_person" }
  subject { RemoveDocumentsAssociatedToPerson.new(given_task_name, double(:current_scope => nil)) }

  describe "given a task name" do
    it "has the given task name" do
      expect(subject.name).to eql given_task_name
    end
  end
  describe "remove_documents_associated_to_person", dbclean: :after_each do
    let(:person) { FactoryGirl.create(:person)}
    let(:document) {FactoryGirl.build(:document, subject:"notices", title:"Sample Notice")}
    let(:bucket_name)         { 'notices' }
    let(:doc_id)              { "urn:openhbx:terms:v1:file_storage:s3:bucket:#{bucket_name}{#sample-key" }

    before(:each) do
      person.documents << document
      allow(ENV).to receive(:[]).with("hbx_id").and_return(person.hbx_id)
      allow(ENV).to receive(:[]).with("doc_id").and_return(document.id)
      allow(ENV).to receive(:[]).with("title").and_return("Sample Notice")
    end
    it "should remove the documents based on id" do
      doc = person.documents.count
      subject.migrate
      person.reload
      expect(person.documents.count).to be 0
    end
  end
end