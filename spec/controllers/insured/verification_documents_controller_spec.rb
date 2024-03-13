require 'rails_helper'

if ExchangeTestingConfigurationHelper.individual_market_is_enabled?
RSpec.describe Insured::VerificationDocumentsController, :type => :controller do
  let(:user) { FactoryBot.create(:user) }
  let(:person) { FactoryBot.build(:person, :with_consumer_role) }
  let(:consumer_role) { {consumer_role: ''} }
  let(:consumer_wrapper) { double }
  let(:admin_person) do
    FactoryBot.create(:person, :with_hbx_staff_role).tap do |person|
      FactoryBot.create(:permission, :super_admin).tap do |permission|
        person.hbx_staff_role.update_attributes(permission_id: permission.id)
      end
    end
  end
  let(:admin_user) { FactoryBot.create(:user, :with_hbx_staff_role, :person => admin_person) }

  context "Failed Upload" do
    context "when person has no consumer_role" do
      it "should error with error doc_params" do
        request.env["HTTP_REFERER"] = "/home"
        _person = create(:person, user: user)
        sign_in user
        post :upload, params: { consumer_role: '' }
        expect(flash[:notice]).not_to be_present
        expect(response).to have_http_status(:redirect)
        expect(flash[:error]).to eq "No consumer role exists, you are not authorized to upload documents"
      end
    end

    context "when person has consumer_role but not ridp verified" do
      it "redirects" do
        request.env["HTTP_REFERER"] = "/home"
        person = create(:person, :with_consumer_role, user: user)
        _family  = create(:family, :with_primary_family_member, person: person)

        sign_in user
        post :upload, params: { consumer_role: consumer_role }
        expect(flash[:error]).to be_present
      end
    end

    context "when person has consumer_role who is ridp verified but no file is passed" do
      it "redirects" do
        request.env["HTTP_REFERER"] = "/home"
        person = create(:person, :with_consumer_role, user: user)
        person.consumer_role.move_identity_documents_to_verified

        sign_in user
        post :upload, params: { consumer_role: consumer_role }
        expect(flash[:error]).to eq "File not uploaded. Please select the file to upload."
      end
    end
  end

  context "Successful Save" do
    context "verification document upload" do
      context "Primary member with ridp verified logged in" do
        describe "file upload" do
          let(:person) { FactoryBot.create(:person, :with_consumer_role, user: user) }
          let(:temp_file) { double }
          let(:bucket_name) { 'id-verification' }
          let(:doc_uri) { "doc_uri" }
          let(:family) { double("Family", :update_family_document_status! => true)}

          before do
            allow_any_instance_of(Insured::VerificationDocumentsController).to receive(:add_type_history_element)
            allow_any_instance_of(Insured::VerificationDocumentsController).to receive(:file_name).and_return("sample-filename")
            allow_any_instance_of(Insured::VerificationDocumentsController).to receive(:update_vlp_documents).with("sample-filename", doc_uri).and_return(true)
            person.consumer_role.move_identity_documents_to_verified
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

          it "does not allow docx files to be uploaded" do
            file = fixture_file_upload("#{Rails.root}/test/fake_sample.docx.jpg")
            params = { person: {consumer_role: person.consumer_role}, file: [file] }
            post :upload, params: params

            expect(flash[:error]).to include("Unable to upload file.")
          end
        end
      end
      context "Admin is logged in and accessing consumer" do
        describe "file upload" do
          let(:person) { FactoryBot.create(:person, :with_consumer_role, user: user) }
          let(:temp_file) { double }
          let(:bucket_name) { 'id-verification' }
          let(:doc_uri) { "doc_uri" }
          let(:family) { double("Family", :update_family_document_status! => true)}

          before do
            allow_any_instance_of(Insured::VerificationDocumentsController).to receive(:add_type_history_element)
            allow_any_instance_of(Insured::VerificationDocumentsController).to receive(:file_name).and_return("sample-filename")
            allow_any_instance_of(Insured::VerificationDocumentsController).to receive(:update_vlp_documents).with("sample-filename", doc_uri).and_return(true)
            person.consumer_role.move_identity_documents_to_verified
            session[:person_id] = person.id.to_s
            controller.instance_variable_set(:"@family", family)
            sign_in admin_user
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

          it "does not allow docx files to be uploaded" do
            file = fixture_file_upload("#{Rails.root}/test/fake_sample.docx.jpg")
            params = { person: {consumer_role: person.consumer_role}, file: [file] }
            post :upload, params: params

            expect(flash[:error]).to include("Unable to upload file.")
          end
        end
      end
    end

    context "Failed Download" do
      it "fails with an error message" do
        person = create(:person, :with_consumer_role, user: user)
        person.consumer_role.move_identity_documents_to_verified
        allow_any_instance_of(Insured::VerificationDocumentsController).to receive(:get_document).and_return(nil)
        allow_any_instance_of(Insured::VerificationDocumentsController).to receive(:vlp_docs_clean).and_return(true)
        sign_in user
        get :download, params: { key:"sample-key" }
        expect(flash[:error]).to eq("File does not exist or you are not authorized to access it.")
      end
    end

    context "Successful Download" do
      it "downloads a file" do
        person = create(:person, :with_consumer_role, user: user)
        person.consumer_role.move_identity_documents_to_verified
        allow_any_instance_of(Insured::VerificationDocumentsController).to receive(:vlp_docs_clean).and_return(true)
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
