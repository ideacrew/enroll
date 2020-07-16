require "rails_helper"

module Operations
  module Cartafact
    RSpec.describe Upload do

      subject do
        described_class.new.call(params)
      end

      let(:tempfile) do
        tf = Tempfile.new('test.pdf')
        tf.write("DATA GOES HERE")
        tf.rewind
        tf
      end

      let(:user)             { FactoryBot.create(:user) }
      let!(:site)            { create(:benefit_sponsors_site, :with_benefit_market, :as_hbx_profile, Settings.site.key) }
      let(:organization)     { FactoryBot.create(:benefit_sponsors_organizations_general_organization, :with_aca_shop_dc_employer_profile, site: site)}
      let(:employer_profile) {organization.employer_profile}
      let(:doc_storage) {{"title"=>"untitled",
                          "language"=>"en",
                          "format"=>"application/octet-stream",
                          "source"=>"enroll_system",
                          "type"=>"notice",
                          "subjects"=>[{"id"=>"BSON::ObjectId.new.to_s", "type"=>"test"}],
                          "id"=>BSON::ObjectId.new.to_s,
                          "extension"=>"pdf"
      }}

      describe 'given empty resource' do
        let(:params) {{resource: nil, file_params: {subject: 'test', body: 'test', file: Rack::Test::UploadedFile.new(tempfile, "application/pdf")}, user: user}}
        let(:error_message) {{:message => ['Please find valid resource to create document.']}}

        it 'fails' do
          expect(subject).not_to be_success
          expect(subject.failure).to eq error_message
        end
      end

      describe "when response has empty subjects" do
        let(:params) { {resource: employer_profile,
                        file_params: {subject: 'test', body: 'test', file: Rack::Test::UploadedFile.new(tempfile, "application/pdf")},
                        user: user }}
        let(:error_message) {{:subjects => ['Missing attributes for subjects']}}

        it "fails" do
          doc_storage[:subjects] = []
          result = Operations::Cartafact::Upload.new.validate_params(doc_storage.transform_keys(&:to_sym))
          expect(result).not_to be_success
          expect(result.failure).to eq error_message
        end
      end

      describe "when response has empty id" do
        let(:params) { {resource: employer_profile,
                        file_params: {subject: 'test', body: 'test', file: Rack::Test::UploadedFile.new(tempfile, "application/pdf")},
                        user: user }}
        let(:error_message) {{:id => ['Doc storage Identifier is blank']}}

        it "fails" do
          doc_storage[:id] = ""
          result = Operations::Cartafact::Upload.new.validate_params(doc_storage.transform_keys(&:to_sym))
          expect(result).not_to be_success
          expect(result.failure).to eq error_message
        end
      end

      describe "when response has empty type" do
        let(:params) { {resource: employer_profile,
                        file_params: {subject: 'test', body: 'test', file: Rack::Test::UploadedFile.new(tempfile, "application/pdf")},
                        user: user }}
        let(:error_message) {{:type => ['Please enter document type']}}

        it "fails" do
          doc_storage[:type] = ""
          result = Operations::Cartafact::Upload.new.validate_params(doc_storage.transform_keys(&:to_sym))
          expect(result).not_to be_success
          expect(result.failure).to eq error_message
        end
      end

      describe "when response has empty source" do
        let(:params) { {resource: employer_profile,
                        file_params: {subject: 'test', body: 'test', file: Rack::Test::UploadedFile.new(tempfile, "application/pdf")},
                        user: user }}
        let(:error_message) {{:source => ['Invalid source']}}

        it "fails" do
          doc_storage[:source] = ""
          result = Operations::Cartafact::Upload.new.validate_params(doc_storage.transform_keys(&:to_sym))
          expect(result).not_to be_success
          expect(result.failure).to eq error_message
        end
      end

      describe "passing valid data" do
        let(:params) { {resource: employer_profile,
                        file_params: {subject: 'test', body: 'test', file: Rack::Test::UploadedFile.new(tempfile, "application/pdf")},
                        user: user }}

        it "success" do
          validated_params = Operations::Cartafact::Upload.new.validate_params(doc_storage.transform_keys(&:to_sym))
          file_entity = Operations::Cartafact::Upload.new.create_file_entity(validated_params.value!)
          file = Operations::Cartafact::Upload.new.create_document(employer_profile, params[:file_params], file_entity.value!.to_h)
          expect(file.success?).to eq true
        end
      end
    end
  end
end
