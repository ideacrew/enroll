# frozen_string_literal: true

require 'rails_helper'

# spec to test insured/verification_documents_controller
if ExchangeTestingConfigurationHelper.individual_market_is_enabled?
  RSpec.describe Insured::VerificationDocumentsController, :type => :controller, dbclean: :after_each do
    let(:person) { FactoryBot.create(:person, :with_consumer_role, :with_active_consumer_role) }
    let(:consumer_role) { person.consumer_role }
    let(:user) { FactoryBot.create(:user, person: person) }
    let(:family) { FactoryBot.create(:family, :with_primary_family_member, person: person)}
    let(:consumer_role_params) { { consumer_role: '' } }
    let(:admin_person) do
      FactoryBot.create(:person, :with_hbx_staff_role).tap do |person|
        FactoryBot.create(:permission, :super_admin).tap do |permission|
          person.hbx_staff_role.update_attributes(permission_id: permission.id)
        end
      end
    end
    let(:admin_user) { FactoryBot.create(:user, :with_hbx_staff_role, :person => admin_person) }

    before :each do
      allow(EnrollRegistry).to receive(:feature_enabled?).and_call_original
      allow(EnrollRegistry).to receive(:feature_enabled?).with(:enable_alive_status).and_return(true)
      family
      consumer_role&.move_identity_documents_to_verified
    end

    context "Failed Upload" do
      context "when person has no consumer_role" do
        let(:person) { FactoryBot.create(:person) }

        it "should error with error doc_params" do
          request.env["HTTP_REFERER"] = "/home"
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
          sign_in user
          post :upload, params: consumer_role_params
          expect(flash[:error]).to be_present
        end
      end

      context "when person has consumer_role who is ridp verified but no file is passed" do
        it "redirects" do
          request.env["HTTP_REFERER"] = "/home"
          sign_in user
          post :upload, params: consumer_role_params
          expect(flash[:error]).to eq "File not uploaded. Please select the file to upload."
        end
      end
    end

    context "Successful Save" do
      context "verification document upload" do
        context "Primary member with ridp verified logged in" do
          describe "file upload" do
            let(:temp_file) { double }
            let(:bucket_name) { 'id-verification' }
            let(:doc_uri) { "doc_uri" }

            before do
              allow_any_instance_of(Insured::VerificationDocumentsController).to receive(:add_type_history_element)
              allow_any_instance_of(Insured::VerificationDocumentsController).to receive(:file_name).and_return("sample-filename")
              allow_any_instance_of(Insured::VerificationDocumentsController).to receive(:update_vlp_documents).with("sample-filename", doc_uri).and_return(true)
              controller.instance_variable_set(:"@family", family)
              sign_in user
            end

            it "uploads file successfully and updates the family doc status" do
              file = fixture_file_upload("#{Rails.root}/test/uhic.jpg")
              allow(Aws::S3Storage).to receive(:save).and_return(doc_uri)
              params = { person: {consumer_role: consumer_role}, file: [file] }
              post :upload, params: params

              expect(flash[:notice]).to eq("File Saved")
            end

            # does not allow invalid files to be uploaded
            it "does not allow docx files to be uploaded" do
              file = fixture_file_upload("#{Rails.root}/test/sample.docx")
              params = { person: {consumer_role: consumer_role}, file: [file] }
              post :upload, params: params

              expect(flash[:error]).to include("Unable to upload file.")
            end

          end

          context 'uploading alive_status verification documentation' do
            let(:alive_status_verification) { person.verification_type_by_name('Alive Status') }
            let(:file) { fixture_file_upload("#{Rails.root}/test/uhic.jpg") }
            let(:doc_uri) { 'doc_uri' }
            let(:params) { { person: { consumer_role: consumer_role }, file: [file] } }

            before do
              allow(EnrollRegistry[:alive_status].feature).to receive(:is_enabled).and_return(true)
              allow(Aws::S3Storage).to receive(:save).and_return(doc_uri)
              allow(controller).to receive(:file_name).and_return("sample-filename")
              allow(controller).to receive(:update_vlp_documents).with("sample-filename", doc_uri).and_return(true)
              controller.instance_variable_set(:"@family", family)
              controller.instance_variable_set(:"@verification_type", alive_status_verification)
              sign_in user
            end

            context "when the validation_status is not 'outstanding'" do
              it 'will not allow upload' do
                post :upload, params: params

                expect(flash[:error]).to eq('You are not authorized to upload this document')
              end
            end

            context "when the validation_status is 'outstanding'" do
              it 'will allow upload' do
                alive_status_verification.update(validation_status: 'outstanding')
                post :upload, params: params

                expect(flash[:notice]).to eq("File Saved")
              end
            end
          end
        end

        context "Admin is logged in and accessing consumer" do
          describe "file upload" do
            let(:temp_file) { double }
            let(:bucket_name) { 'id-verification' }
            let(:doc_uri) { "doc_uri" }

            before do
              allow(EnrollRegistry[:alive_status].feature).to receive(:is_enabled).and_return(true)
              allow_any_instance_of(Insured::VerificationDocumentsController).to receive(:add_type_history_element)
              allow_any_instance_of(Insured::VerificationDocumentsController).to receive(:file_name).and_return("sample-filename")
              allow_any_instance_of(Insured::VerificationDocumentsController).to receive(:update_vlp_documents).with("sample-filename", doc_uri).and_return(true)
              session[:person_id] = person.id.to_s
              controller.instance_variable_set(:"@family", family)
              sign_in admin_user
            end

            it "uploads file successfully and updates the family doc status" do
              file = fixture_file_upload("#{Rails.root}/test/uhic.jpg")
              allow(Aws::S3Storage).to receive(:save).and_return(doc_uri)
              params = { person: {consumer_role: consumer_role}, file: [file] }
              post :upload, params: params

              expect(flash[:notice]).to eq("File Saved")
            end

            context 'uploading alive_status verification documentation' do
              let(:alive_status_verification) { person.verification_type_by_name('Alive Status') }

              before do
                allow(EnrollRegistry[:alive_status].feature).to receive(:is_enabled).and_return(true)
                file = fixture_file_upload("#{Rails.root}/test/uhic.jpg")
                allow(Aws::S3Storage).to receive(:save).and_return(doc_uri)
                controller.instance_variable_set(:"@verification_type", alive_status_verification)
                session[:person_id] = person.id.to_s
                params = { person: { consumer_role: consumer_role }, file: [file] }
                post :upload, params: params
              end

              it "uploads alive_status verification file successfully" do
                expect(flash[:notice]).to eq("File Saved")
              end
            end

            # does not allow invalid files to be uploaded
            it "does not allow docx files to be uploaded" do
              file = fixture_file_upload("#{Rails.root}/test/sample.docx")
              params = { person: {consumer_role: consumer_role}, file: [file] }
              post :upload, params: params

              expect(flash[:error]).to include("Unable to upload file.")
            end

            it "does not allow docx files to be uploaded" do
              file = fixture_file_upload("#{Rails.root}/test/fake_sample.docx.jpg")
              params = { person: {consumer_role: consumer_role}, file: [file] }
              post :upload, params: params

              expect(flash[:error]).to include("Unable to upload file.")
            end
          end
        end
      end

      context "Failed Download" do
        it "fails with an error message" do
          allow_any_instance_of(Insured::VerificationDocumentsController).to receive(:get_document).and_return(nil)
          allow_any_instance_of(Insured::VerificationDocumentsController).to receive(:vlp_docs_clean).and_return(true)
          sign_in user
          get :download, params: { key: "sample-key" }
          expect(flash[:error]).to eq("File does not exist or you are not authorized to access it.")
        end
      end

      context "Successful Download" do
        it "downloads a file" do
          allow_any_instance_of(Insured::VerificationDocumentsController).to receive(:vlp_docs_clean).and_return(true)
          allow_any_instance_of(Insured::VerificationDocumentsController).to receive(:get_document).with('sample-key').and_return(VlpDocument.new)
          sign_in user
          get :download, params: { key: "sample-key" }
          expect(flash[:error]).to be_nil
          expect(response.status).to eq(200)
        end
      end

      context 'alive_status download' do
        let(:alive_status_verification) { person.verification_type_by_name('Alive Status') }
        let(:vlp_doc) { VlpDocument.new }

        before do
          allow(EnrollRegistry[:alive_status].feature).to receive(:is_enabled).and_return(true)
          allow(controller).to receive(:vlp_docs_clean).and_return(true)
          allow(consumer_role).to receive(:find_vlp_document_by_key).with('sample-key').and_return(vlp_doc)
          allow(vlp_doc).to receive(:documentable).and_return(alive_status_verification)
        end

        context 'as a user' do
          before do
            sign_in user
          end

          context 'when an alive_status does not have an outstanding validation status' do
            it 'will not download' do
              get :download, params: { key: "sample-key" }

              expect(flash[:error]).to eq 'File does not exist or you are not authorized to access it.'
              expect(response).to have_http_status(:redirect)
            end
          end

          context 'when an alive_status has an outstanding validation status' do
            it 'will download successfully' do
              alive_status_verification.update(validation_status: 'outstanding')
              get :download, params: { key: "sample-key" }

              expect(flash[:error]).to be_nil
              expect(response).to have_http_status(:success)
            end
          end
        end

        context 'as an admin' do
          before do
            allow(controller).to receive(:set_current_person).and_return(true)
            controller.instance_variable_set(:"@person", person)
            session[:person_id] = person.id.to_s

            sign_in admin_user
          end

          it 'will download regardless of verification validation_status' do
            get :download, params: { key: "sample-key" }

            expect(flash[:error]).to be_nil
            expect(response).to have_http_status(:success)
          end
        end
      end
    end
  end
end
