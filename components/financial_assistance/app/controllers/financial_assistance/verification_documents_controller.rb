# frozen_string_literal: true

module FinancialAssistance
  # controller for cost saving documents
  class VerificationDocumentsController < FinancialAssistance::ApplicationController
    include ApplicationHelper
    include VerificationHelper

    before_action :fetch_applicant
    before_action :updateable?, :find_type, only: [:upload, :update_evidence]
    before_action :set_document, only: [:destroy]

    def upload
      @doc_errors = []
      if params[:file]
        params[:file].each do |file|
          doc_uri = Aws::S3Storage.save(file_path(file), 'id-verification')
          if doc_uri.present?
            if update_documents(file_name(file), doc_uri)
              add_verification_history(file)
              flash[:notice] = "File Saved"
            else
              flash[:error] = "Could not save file. #{@doc_errors.join('. ')}"
              redirect_to(:back)
              break
            end
          else
            flash[:error] = "Could not save file"
          end
        end
      else
        flash[:error] = "File not uploaded. Please select the file to upload."
      end
      redirect_to main_app.verification_insured_families_path
    end

    def download
      document = get_document(params[:key])
      if document.present?
        bucket = env_bucket_name('id-verification')
        uri = "urn:openhbx:terms:v1:file_storage:s3:bucket:#{bucket}##{params[:key]}"
        send_data Aws::S3Storage.find(uri), download_options(document)
      else
        flash[:error] = "File does not exist or you are not authorized to access it."
        redirect_to main_app.verification_insured_families_path
      end
    end

    def update_evidence
      update_reason = params[:verification_reason]
      admin_action = params[:admin_action]
      reasons_list = FinancialAssistance::Document::VERIFICATION_REASONS + FinancialAssistance::Document::REJECT_REASONS
      if reasons_list.include?(update_reason)
        verification_result = admin_verification_action(admin_action, @evidence, update_reason)
        message = (verification_result.is_a? String) ? verification_result : "Person verification successfully approved."
        flash[:success] =  message
      else
        flash[:error] = "Please provide a verification reason."
      end

      redirect_to main_app.verification_insured_families_path
    end

    def destroy
      @document.delete if @evidence.type_unverified?
      if @document.destroyed?
        @docs_owner.save!

        if (@evidence.documents - [@document]).empty?
          @evidence.update_attributes(:validation_status => "outstanding", :update_reason => "all documents deleted")
          flash[:danger] = "All documents were deleted. Action needed"
        else
          flash[:success] = "Document deleted."
        end
      else
        flash[:danger] = "Document can not be deleted because type is verified."
      end
      respond_to do |format|
        format.html { redirect_to main_app.verification_insured_families_path }
        format.js
      end
    end

    private

    def updateable?
      authorize Family, :updateable?
    end

    def set_document
      find_type
      @document = get_document(params[:doc_key])
      error_message = l10n("documents.controller.missing_document_message", contact_center_phone_number: EnrollRegistry[:enroll_app].settings(:contact_center_short_number).item) if @document.blank?
      redirect_back(fallback_location: main_app.verification_insured_families_path, :flash => {error: error_message}) if @document.blank?
    end

    def fetch_applicant
      @applicant = if params[:applicant_id]
                     FinancialAssistance::Applicant.find(params[:applicant_id])
                   elsif current_user.try(:person).try(:agent?) && session[:person_id].present?
                     FinancialAssistance::Applicant.find(session[:person_id])
                   end

      redirect_to maain_app.logout_saml_index_path unless fetch_applicant_succeeded?
    end

    def fetch_applicant_succeeded?
      return true if @applicant
      message = {}
      message[:message] = 'Application Exception - applicant required'
      message[:session_person_id] = session[:person_id]
      message[:user_id] = current_user.id
      message[:oim_id] = current_user.oim_id
      message[:url] = request.original_url
      log(message, :severity => 'error')
      false
    end

    def find_docs_owner
      @docs_owner = ::FinancialAssistance::Applicant.find(params[:applicant_id]) if params[:applicant_id]
    end

    def find_type
      fetch_applicant
      find_docs_owner
      @evidence = @docs_owner.evidences.find(params[:evidence]) if params[:evidence]
    end

    def file_path(file)
      file.tempfile.path
    end

    def file_name(file)
      file.original_filename
    end

    def update_documents(title, file_uri)
      document = @evidence.documents.build
      success = document.update_attributes({:identifier => file_uri, :subject => title, :title => title, :status => "downloaded"})
      @evidence.update_attributes(:rejected => false, :eligibility_status => "review", :update_reason => "document uploaded")
      @doc_errors = document.errors.full_messages unless success
      @docs_owner.save!
    end

    def get_document(key)
      documents = @applicant.evidences.flat_map(&:documents)

      documents.detect do |doc|
        next if doc.identifier.blank?
        doc_key = doc.identifier.split('#').last
        doc_key == key
      end
    end

    def download_options(document)
      options = {}
      options[:content_type] = document.format
      options[:filename] = document.title
      options
    end

    def add_verification_history(file)
      actor = current_user ? current_user.email : "external source or script"
      action = "Upload #{file_name(file)}" if params[:action] == "upload"
      @evidence.add_verification_history(action: action, modifier: actor)
    end
  end
end
