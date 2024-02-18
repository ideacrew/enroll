require 'rails_helper'

if ExchangeTestingConfigurationHelper.individual_market_is_enabled?
RSpec.describe Insured::VerificationDocumentsController, :type => :controller do
  let(:user) { FactoryBot.create(:user) }
  let(:person) { FactoryBot.build(:person, :with_consumer_role) }
  let(:consumer_role) { {consumer_role: ''} }
  let(:consumer_wrapper) { double }

  context "Failed Upload" do
    xit "redirects" do
      allow_any_instance_of(Insured::VerificationDocumentsController).to receive(:get_family)
      allow_any_instance_of(Insured::VerificationDocumentsController).to receive(:person_consumer_role)
      allow_any_instance_of(Insured::VerificationDocumentsController).to receive(:params_clean_vlp_documents).and_return({sample: 'sample'})

      sign_in user
      post :upload, consumer_role: consumer_role
      expect(flash[:error]).to be_present
    end

    xit "should error with error doc_params" do
      request.env["HTTP_REFERER"] = "/home"
      allow(user).to receive(:person).and_return person
      sign_in user
      post :upload, {consumer_role: ""}
      expect(flash[:notice]).not_to be_present
      expect(response).to have_http_status(:redirect)
      expect(flash[:error]).to eq "File not uploaded. Document type and/or document fields not provided "
    end
  end

  context "Successful Save" do

    describe "file upload" do
      let(:file) { double }
      let(:temp_file) { double }
      let(:consumer_role_params) {}
      let(:params) { {person: {consumer_role: ''}, file: file} }
      let(:bucket_name) { 'id-verification' }
      let(:doc_id) { "urn:openhbx:terms:v1:file_storage:s3:bucket:#{bucket_name}{#sample-key" }
      let(:file_path) { File.dirname(__FILE__) } # a sample file path
      let(:cleaned_params) { {"0" => {"subject" => "I-327 (Reentry Permit)", "id" => "55e7fef5536167bb822e0000", "alien_number" => "999999999"}} }

      xit "redirects" do
        allow(file).to receive(:original_filename).and_return("some-filename")
        allow(file).to receive(:tempfile).and_return(temp_file)
        allow(temp_file).to receive(:path)
        allow_any_instance_of(Insured::VerificationDocumentsController).to receive(:get_family)
        allow_any_instance_of(Insured::VerificationDocumentsController).to receive(:person_consumer_role)
        allow_any_instance_of(Insured::VerificationDocumentsController).to receive(:file_path).and_return(file_path)
        allow_any_instance_of(Insured::VerificationDocumentsController).to receive(:file_name).and_return("sample-filename")
        allow_any_instance_of(Insured::VerificationDocumentsController).to receive(:params_clean_vlp_documents).and_return(cleaned_params)
        allow_any_instance_of(Insured::VerificationDocumentsController).to receive(:update_vlp_documents).with(cleaned_params, "sample-filename", doc_id).and_return(true)
        allow(Aws::S3Storage).to receive(:save).with(file_path, bucket_name).and_return(doc_id)
        sign_in user
        post :upload, params: params
        expect(flash[:notice]).to be_present
      end
    end

    context "verification document upload" do

    describe "file upload" do
      let(:person) { FactoryBot.create(:person, :with_consumer_role) }
      let(:temp_file) { double }
      let(:consumer_role_params) {}
      let(:bucket_name) { 'id-verification' }
      let(:doc_uri) { "doc_uri" }
      let(:family) { double("Family", :update_family_document_status! => true)}

      before do
        allow_any_instance_of(Insured::VerificationDocumentsController).to receive(:find_docs_owner).and_return(person)
        allow_any_instance_of(Insured::VerificationDocumentsController).to receive(:get_family)
        allow_any_instance_of(Insured::VerificationDocumentsController).to receive(:add_type_history_element)
        allow_any_instance_of(Insured::VerificationDocumentsController).to receive(:set_current_person).and_return(person)
        allow_any_instance_of(Insured::VerificationDocumentsController).to receive(:person_consumer_role)
        allow_any_instance_of(Insured::VerificationDocumentsController).to receive(:file_name).and_return("sample-filename")
        allow_any_instance_of(Insured::VerificationDocumentsController).to receive(:update_vlp_documents).with("sample-filename", doc_uri).and_return(true)

        controller.instance_variable_set(:"@family", family)
        sign_in user
      end

      it "uploads file successfully and updates the family doc status" do
        file = fixture_file_upload("#{Rails.root}/test/uhic.jpg")
        allow(Aws::S3Storage).to receive(:save).and_return(doc_uri)
        params = { person: {consumer_role: person.consumer_role}, file: [file] }
        post :upload, params: params

        expect(flash[:notice]).to eq("File Saved")
      end

      # does not allow invalid files to be uploaded
      it "does not allow docx files to be uploaded" do
        file = fixture_file_upload("#{Rails.root}/test/sample.docx")
        params = { person: {consumer_role: person.consumer_role}, file: [file] }
        post :upload, params: params

        expect(flash[:error]).to include("Unable to upload file.")
      end
     end
    end

    context "Failed Download" do
      it "fails with an error message" do
        allow_any_instance_of(Insured::VerificationDocumentsController).to receive(:get_family)
        allow_any_instance_of(Insured::VerificationDocumentsController).to receive(:get_document).and_return(nil)
        allow_any_instance_of(Insured::VerificationDocumentsController).to receive(:vlp_docs_clean).and_return(true)
        sign_in user
        get :download, params: { key:"sample-key" }
        expect(flash[:error]).to eq("File does not exist or you are not authorized to access it.")
      end
    end

    context "Successful Download" do
      it "downloads a file" do
        allow_any_instance_of(Insured::VerificationDocumentsController).to receive(:vlp_docs_clean).and_return(true)
        allow_any_instance_of(Insured::VerificationDocumentsController).to receive(:get_family)
        allow_any_instance_of(Insured::VerificationDocumentsController).to receive(:get_document).with('sample-key').and_return(VlpDocument.new)
        sign_in user
        get :download, params: { key:"sample-key" }
        expect(flash[:error]).to be_nil
        expect(response.status).to eq(200)
      end
    end

  end
end
end
