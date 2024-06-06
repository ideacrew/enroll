# frozen_string_literal: true

require 'rails_helper'

if ExchangeTestingConfigurationHelper.individual_market_is_enabled?
  RSpec.describe Insured::RidpDocumentsController, type: :controller, dbclean: :after_each do
    let(:person) { FactoryBot.create(:person, :with_consumer_role) }
    let(:consumer_user) { FactoryBot.create(:user, person: person) }
    let(:consumer_family) { FactoryBot.create(:family, :with_primary_family_member, person: person) }
    let(:consumer_role) { person.consumer_role }
    let!(:resident_user) {  FactoryBot.create(:user) }
    let!(:resident_role) { FactoryBot.create(:person, :with_resident_role, user: resident_user) }
    let(:resident_family) { FactoryBot.create(:family, :with_primary_family_member, person: resident_role) }
    let(:admin_person) do
      FactoryBot.create(:person, :with_hbx_staff_role).tap do |person|
        FactoryBot.create(:permission, :super_admin).tap do |permission|
          person.hbx_staff_role.update_attributes(permission_id: permission.id)
        end
      end
    end
    let(:admin_user) { FactoryBot.create(:user, :with_hbx_staff_role, :person => admin_person) }

    before :each do
      consumer_family
      consumer_role.move_identity_documents_to_verified
      resident_family
    end

    context "Redirects non-logged in user" do
      it "redirects when current_user is nil" do
        expect(controller).to receive(:redirect_to)
        controller.send(:get_person)
      end
    end

    context "Failed Upload" do
      context "sign in as resident user" do
        it "redirects" do
          request.env["HTTP_REFERER"] = "/home"
          sign_in resident_user
          post :upload
          expect(flash[:error]).to be_present
        end
      end

      context "sign in as consumer user with no file params" do
        it "should error with error doc_params" do
          request.env["HTTP_REFERER"] = "/home"
          sign_in consumer_user
          post :upload
          expect(flash[:notice]).not_to be_present
          expect(response).to have_http_status(:redirect)
          expect(flash[:error]).to eq "File not uploaded. Please select the file to upload."
        end
      end
    end

    context "Successful Save" do
      context "when consumer is signed in" do
        describe "file upload" do
          let(:file) { double }
          let(:temp_file) { double }
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
            allow_any_instance_of(Insured::RidpDocumentsController).to receive(:file_path).and_return(file_path)
            allow_any_instance_of(Insured::RidpDocumentsController).to receive(:file_name).and_return("sample-filename")
            allow_any_instance_of(Insured::RidpDocumentsController).to receive(:update_ridp_documents).with("sample-filename", doc_id).and_return(true)
            allow(Aws::S3Storage).to receive(:save).with(file_path, bucket_name).and_return(doc_id)
            sign_in consumer_user
            file = fixture_file_upload("#{Rails.root}/test/uhic.jpg")
            params[:file] = [file]
            post :upload, params: params
          end

          it "redirects" do
            expect(flash[:notice]).to be_present
          end
        end
      end

      context "when admin is signed in" do
        describe "file upload" do
          let(:file) { double }
          let(:temp_file) { double }
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
            allow_any_instance_of(Insured::RidpDocumentsController).to receive(:file_path).and_return(file_path)
            allow_any_instance_of(Insured::RidpDocumentsController).to receive(:file_name).and_return("sample-filename")
            allow_any_instance_of(Insured::RidpDocumentsController).to receive(:update_ridp_documents).with("sample-filename", doc_id).and_return(true)
            allow(Aws::S3Storage).to receive(:save).with(file_path, bucket_name).and_return(doc_id)
            session[:person_id] = person.id.to_s
            sign_in admin_user
            file = fixture_file_upload("#{Rails.root}/test/uhic.jpg")
            params[:file] = [file]
            post :upload, params: params
          end

          it "redirects" do
            expect(flash[:notice]).to be_present
          end
        end
      end


      context "Failed Download" do
        it "fails with an error message" do
          request.env["HTTP_REFERER"] = "/home"
          allow_any_instance_of(Insured::RidpDocumentsController).to receive(:ridp_docs_clean).and_return(true)
          sign_in consumer_user
          get :download, params: { key: "sample-key" }
          expect(flash[:error]).to eq("File does not exist or you are not authorized to access it.")
        end
      end

      context "Successful Download" do
        it "downloads a file" do
          allow_any_instance_of(Insured::RidpDocumentsController).to receive(:ridp_docs_clean).and_return(true)
          allow_any_instance_of(Insured::RidpDocumentsController).to receive(:get_document).with('sample-key').and_return(RidpDocument.new)
          sign_in consumer_user
          get :download, params: { key: "sample-key" }
          expect(flash[:error]).to be_nil
          expect(response.status).to eq(200)
        end
      end

    end
  end
end
