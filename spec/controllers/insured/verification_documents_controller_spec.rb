require 'rails_helper'

RSpec.describe Insured::VerificationDocumentsController, :type => :controller do
  let(:user) { FactoryGirl.create(:user) }
  let(:person) { double }
  let(:consumer_role) { {consumer_role: ''} }
  let(:consumer_wrapper) { double }


  context "Fails to upload file" do
    it "redirects" do
      allow_any_instance_of(Insured::VerificationDocumentsController).to receive(:get_family)
      allow_any_instance_of(Insured::VerificationDocumentsController).to receive(:person_consumer_role)
      sign_in user
      post :upload, consumer_role: consumer_role
      expect(flash[:error]).to be_present
    end
  end

  context "Succeeds to save file" do

    describe "" do
      let(:file) { double }
      let(:temp_file) { double }
      let(:consumer_role) { {consumer_role: '', file: file} }
      let(:doc_id) { 'erewrewrewr234214' }

      it "redirects" do
        allow(file).to receive(:tempfile).and_return(temp_file)
        allow(temp_file).to receive(:path)
        allow_any_instance_of(Insured::VerificationDocumentsController).to receive(:build_document).with(anything).and_return(double)
        allow_any_instance_of(Insured::VerificationDocumentsController).to receive(:save_consumer_role).with(anything).and_return(true)
        allow_any_instance_of(Insured::VerificationDocumentsController).to receive(:get_family)
        allow_any_instance_of(Insured::VerificationDocumentsController).to receive(:person_consumer_role)
        allow_any_instance_of(Insured::VerificationDocumentsController).to receive(:file_path).and_return('')
        allow(Aws::S3Storage).to receive(:save).with(anything, anything).and_return(doc_id)
        sign_in user
        post :upload, consumer_role: consumer_role
        expect(flash[:notice]).to be_present
      end
    end
  end
end
