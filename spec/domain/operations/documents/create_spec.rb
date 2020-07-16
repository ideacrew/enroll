require "rails_helper"

module Operations
  module Documents
    RSpec.describe Create do

      subject do
        described_class.new.call(params)
      end

      let(:tempfile) do
        tf = Tempfile.new('test.pdf')
        tf.write("DATA GOES HERE")
        tf.rewind
        tf
      end

      let!(:site)            { create(:benefit_sponsors_site, :with_benefit_market, :as_hbx_profile, Settings.site.key) }
      let(:organization)     { FactoryBot.create(:benefit_sponsors_organizations_general_organization, :with_aca_shop_dc_employer_profile, site: site)}
      let(:employer_profile) {organization.employer_profile}
      let(:doc_payload) {{
          "title": "test",
          "format": "application/pdf",
          "creator": "hbx_staff",
          "subject": "notice",
          "doc_identifier": BSON::ObjectId.new.to_s
      }}

      describe 'given empty resource' do
        let(:params) {{resource: nil,
                       document_params: {subject: 'test', body: 'test', file: Rack::Test::UploadedFile.new(tempfile, "application/pdf")},
                       doc_identifier: BSON::ObjectId.new.to_s}}
        let(:error_message) {{:message => ['Please find valid resource to create document.']}}

        it 'fails' do
          expect(subject).not_to be_success
          expect(subject.failure).to eq error_message
        end
      end

      describe "given empty doc_identifier" do
        let(:params) { {resource: employer_profile,
                        document_params: {subject: 'test', body: 'test', file: Rack::Test::UploadedFile.new(tempfile, "application/pdf")},
                        doc_identifier: "" }}
        let(:error_message) {{:doc_identifier => ['Response missing doc identifier.']}}


        it "fails" do
          expect(subject).not_to be_success
          expect(subject.failure).to eq error_message
        end
      end

      describe "given empty title" do
        let(:params) { {resource: employer_profile,
                        document_params: {subject: 'test', body: 'test', file: Rack::Test::UploadedFile.new(tempfile, "application/pdf")},
                        doc_identifier: BSON::ObjectId.new.to_s }}
        let(:error_message) {{:title => ['Missing title for document.']}}

        it "fails" do
          doc_payload[:title] = ""
          result = Operations::Documents::Create.new.validate_params(doc_payload)
          expect(result).not_to be_success
          expect(result.failure).to eq error_message
        end
      end

      describe "given empty title" do
        let(:params) { {resource: employer_profile,
                        document_params: {subject: 'test', body: 'test', file: Rack::Test::UploadedFile.new(tempfile, "application/pdf")},
                        doc_identifier: BSON::ObjectId.new.to_s }}
        let(:error_message) {{:creator => ['Missing creator for document.']}}

        it "fails" do
          doc_payload[:creator] = ""
          result = Operations::Documents::Create.new.validate_params(doc_payload)
          expect(result).not_to be_success
          expect(result.failure).to eq error_message
        end
      end

      describe "given empty subject" do
        let(:params) { {resource: employer_profile,
                        document_params: {subject: 'test', body: 'test', file: Rack::Test::UploadedFile.new(tempfile, "application/pdf")},
                        doc_identifier: BSON::ObjectId.new.to_s }}
        let(:error_message) {{:subject => ['Missing subject for document.']}}

        it "fails" do
          doc_payload[:subject] = ""
          result = Operations::Documents::Create.new.validate_params(doc_payload)
          expect(result).not_to be_success
          expect(result.failure).to eq error_message
        end
      end

      describe "given empty format" do
        let(:params) { {resource: employer_profile,
                        document_params: {subject: 'test', body: 'test', file: Rack::Test::UploadedFile.new(tempfile, "application/pdf")},
                        doc_identifier: BSON::ObjectId.new.to_s }}
        let(:error_message) {{:format => ['Invalid file format.']}}

        it "fails" do
          doc_payload[:format] = ""
          result = Operations::Documents::Create.new.validate_params(doc_payload)
          expect(result).not_to be_success
          expect(result.failure).to eq error_message
        end
      end

      describe "passing valid data" do
        let(:params) { { resource: employer_profile, message_params: {subject: 'test', body: 'test'}}}

        it "success" do
          validated_params = Operations::Documents::Create.new.validate_params(doc_payload)
          file_entity = Operations::Documents::Create.new.create_document_entity(validated_params.value!)
          document = Operations::Documents::Create.new.create(employer_profile, file_entity.value!.to_h)
          expect(document.success?).to eq true
        end
      end
    end
  end
end
