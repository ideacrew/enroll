require 'rails_helper'

RSpec.describe Insured::RidpDocumentsController, type: :controller, dbclean: :after_each do
  let!(:user) { FactoryBot.create(:user) }
  let!(:person) { FactoryBot.create(:person, :with_consumer_role) }
  let!(:consumer_role) { person.consumer_role }

  context "Redirects non-logged in user" do
    it "redirects when current_user is nil" do
      expect(controller).to receive(:redirect_to)
      controller.send(:get_person)
    end
  end

  context "Failed Upload" do
    it "redirects" do
      request.env["HTTP_REFERER"] = "/home"
      allow_any_instance_of(Insured::RidpDocumentsController).to receive(:get_person)
      allow_any_instance_of(Insured::RidpDocumentsController).to receive(:person_consumer_role)

      sign_in user
      post :upload, params: {consumer_role: consumer_role}
      expect(flash[:error]).to be_present
    end

    it "should error with error doc_params" do
      request.env["HTTP_REFERER"] = "/home"
      allow(user).to receive(:person).and_return person
      sign_in user
      post :upload
      expect(flash[:notice]).not_to be_present
      expect(response).to have_http_status(:redirect)
      expect(flash[:error]).to eq "File not uploaded. Please select the file to upload."
    end
  end

  context "Successful Save" do

    describe "file upload" do
      let(:file) { double }
      let(:temp_file) { double }
      let(:consumer_role_params) {}
      let(:params) { { person: person, file: [file], ridp_verification_type: 'Identity' } }
      let(:bucket_name) { 'id-verification' }
      let(:doc_id) { "urn:openhbx:terms:v1:file_storage:s3:bucket:#{bucket_name}{#sample-key}" }
      let(:file_path) { File.dirname(__FILE__) } # a sample file path
      let(:cleaned_params) { {"0" => {"subject" => "I-327 (Reentry Permit)", "id" => "55e7fef5536167bb822e0000", "alien_number" => "999999999"}} }

      before :each do
        request.env["HTTP_REFERER"] = "/home"
        allow(file).to receive(:original_filename).and_return("some-filename")
        allow(file).to receive(:tempfile).and_return(temp_file)
        allow(temp_file).to receive(:path)
        allow_any_instance_of(Insured::RidpDocumentsController).to receive(:get_person)
        allow_any_instance_of(Insured::RidpDocumentsController).to receive(:person_consumer_role)
        allow_any_instance_of(Insured::RidpDocumentsController).to receive(:file_path).and_return(file_path)
        allow_any_instance_of(Insured::RidpDocumentsController).to receive(:file_name).and_return("sample-filename")
        allow_any_instance_of(Insured::RidpDocumentsController).to receive(:update_ridp_documents).with("sample-filename", doc_id).and_return(true)
        allow(Aws::S3Storage).to receive(:save).with(file_path, bucket_name).and_return(doc_id)
        sign_in user
        post :upload, params: params
      end

      it "redirects" do
        expect(flash[:notice]).to be_present
      end
    end

    context "Failed Download" do
      it "fails with an error message" do
        request.env["HTTP_REFERER"] = "/home"
        allow_any_instance_of(Insured::RidpDocumentsController).to receive(:get_person)
        allow_any_instance_of(Insured::RidpDocumentsController).to receive(:get_document).and_return(nil)
        allow_any_instance_of(Insured::RidpDocumentsController).to receive(:ridp_docs_clean).and_return(true)
        sign_in user
        get :download, params: { key:"sample-key" }
        expect(flash[:error]).to eq("File does not exist or you are not authorized to access it.")
      end
    end

    context "Successful Download" do
      it "downloads a file" do
        allow_any_instance_of(Insured::RidpDocumentsController).to receive(:ridp_docs_clean).and_return(true)
        allow_any_instance_of(Insured::RidpDocumentsController).to receive(:get_person)
        allow_any_instance_of(Insured::RidpDocumentsController).to receive(:get_document).with('sample-key').and_return(RidpDocument.new)
        sign_in user
        get :download, params: { key:"sample-key" }
        expect(flash[:error]).to be_nil
        expect(response.status).to eq(200)
      end
    end

  end
end
