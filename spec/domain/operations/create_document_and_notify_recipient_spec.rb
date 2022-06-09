# frozen_string_literal: true

require "rails_helper"

# module Operations for class CreateDocumentAndNotifyRecipient
module Operations
  RSpec.describe CreateDocumentAndNotifyRecipient do
    subject do
      described_class.new.call(params)
    end

    let(:person) { FactoryBot.create(:person, :with_consumer_role, :with_family) }
    let(:family) { person.primary_family }
    let(:payload) do
      {
        :title => "Magi_Medicaid_Eligibility_Notice.pdf",
        :creator => "dchl",
        :identifier => nil,
        :description => nil,
        :language => "en",
        :format => "application/pdf",
        :source => "polypress",
        :date => nil,
        :document_type => "notice",
        :subjects => [{:id => person.hbx_id, :type => "Person"}],
        :version => nil,
        :id => "60d5468287bfe40001f5cc33",
        :extension => "pdf",
        :mime_type => "application/octet-stream",
        :file_name => "Magi_Medicaid_Eligibility_Notice.pdf",
        :file_content_type => "application/pdf"
      }
    end
    let(:title) { "Magi Medicaid Eligibility Notice" }

    context 'when valid args are passed' do
      let(:params) { payload }
      it 'should be success' do
        expect(subject).to be_success
      end
    end

    context "when id is missing" do
      let(:params) { payload.except(:id) }
      let(:error_message) { { :message => ["Document Identifier is missing"] } }

      it "fails" do
        expect(subject).not_to be_success
        expect(subject.failure).to eq error_message
      end
    end

    context "when resource id is missing" do
      let(:params) do
        payload[:subjects] = [{ :type => 'Person', :id => nil }]
        payload
      end

      let(:error_message) { { :message => ["Resource id is missing"] } }

      it "fails" do
        expect(subject).not_to be_success
        expect(subject.failure).to eq error_message
      end
    end

    context "passing valid data to documents create operation" do
      it "success" do
        document = Operations::CreateDocumentAndNotifyRecipient.new.create_document(person, payload)
        expect(document.success?).to eq true
      end
    end

    context "create document" do
      it "should be success" do
        document = Operations::CreateDocumentAndNotifyRecipient.new.create_document(person, payload)
        Operations::CreateDocumentAndNotifyRecipient.new.send_secure_message(person, document.success, title)
        expect(person.reload.documents.count).to eq 1
      end
    end

    context "send secure message" do
      it "should be success" do
        document = Operations::CreateDocumentAndNotifyRecipient.new.create_document(person, payload)
        Operations::CreateDocumentAndNotifyRecipient.new.send_secure_message(person, document.success, title)
        expect(person.reload.inbox.messages.size).to eq 2
      end
    end
  end
end
