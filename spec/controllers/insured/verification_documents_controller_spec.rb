require 'rails_helper'

RSpec.describe Insured::VerificationDocumentsController, :type => :controller do
  let(:user) { FactoryGirl.create(:user) }
  let(:person) { double }
  let(:consumer_role) { {consumer_role: ''} }
  let(:consumer_wrapper) { double }

  context "Failed Upload" do
    it "redirects" do
      allow_any_instance_of(Insured::VerificationDocumentsController).to receive(:get_family)
      allow_any_instance_of(Insured::VerificationDocumentsController).to receive(:person_consumer_role)
      allow_any_instance_of(Insured::VerificationDocumentsController).to receive(:params_clean_vlp_documents).and_return({sample:'sample'})

      sign_in user
      post :upload, consumer_role: consumer_role
      expect(flash[:error]).to be_present
    end
  end

  context "Successful Save" do

    describe "file upload" do
      let(:file) { double }
      let(:temp_file) { double }
      let(:consumer_role_params) {}
      let(:params) { {consumer_role: '', file: file} }
      let(:bucket_name) { 'id-verification'}
      let(:doc_id) { "urn:openhbx:terms:v1:file_storage:s3:bucket:#{bucket_name}{#sample-key"}
      let(:file_path) {File.dirname(__FILE__)} # a sample file path
      let(:cleaned_params) {{"2"=>{"subject"=>"I-327 (Reentry Permit)", "id"=>"55e7fef5536167bb822e0000", "alien_number"=>"999999999"}}}


      it "redirects" do
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
        post :upload, params
        expect(flash[:notice]).to be_present
      end
    end
  end
end
