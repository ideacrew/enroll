# frozen_string_literal: true

module FinancialAssistance
  # controller for cost saving documents
  class VerificationDocumentsController < FinancialAssistance::ApplicationController
    include ApplicationHelper
    include VerificationHelper

    before_action :fetch_applicant

    # This is a before_action that checks if the application is a renewal draft and if it is, it sets a flash message and redirects to the applications_path
    # This before_action needs to be called after finding the application
    #
    # @before_action
    # @private
    before_action :check_for_uneditable_application

    before_action :find_type, only: [:upload, :update_evidence, :download]
    before_action :set_document, only: [:destroy]

    def upload
      authorize @applicant

      @doc_errors = []
      if params[:file].blank?
        flash[:error] = "File not uploaded. Please select the file to upload."
      elsif !valid_file_uploads?(params[:file], FileUploadValidator::VERIFICATION_DOC_TYPES)
        redirect_to main_app.verification_insured_families_path
        return
      else
        params[:file].each do |file|
          doc_uri = Aws::S3Storage.save(file_path(file), 'id-verification')
          if doc_uri.present?
            if update_documents(file_name(file), doc_uri)
              add_verification_history(file)
              flash[:notice] = "File Saved"
            else
              flash[:error] = "Could not save file. #{@doc_errors.join('. ')}"
              redirect_back(fallback_location: main_app.verification_insured_families_path)
              break
            end
          else
            flash[:error] = "Could not save file"
          end
        end
      end
      redirect_to main_app.verification_insured_families_path
    end

    def download
      authorize @applicant

      @document = get_document(params[:key])

      if @document.present?
        bucket = env_bucket_name('id-verification')
        uri = "urn:openhbx:terms:v1:file_storage:s3:bucket:#{bucket}##{params[:key]}"
        send_data Aws::S3Storage.find(uri), download_options(@document)
      else
        flash[:error] = "File does not exist or you are not authorized to access it."
        redirect_to main_app.verification_insured_families_path
      end
    end

    def destroy
      authorize @applicant

      @document.delete if @evidence.type_unverified?
      if @document.destroyed?
        add_verification_history(@document)
        @docs_owner.save!

        if (@evidence.documents - [@document]).empty?
          applicant = @evidence.evidenceable
          applicant.set_evidence_outstanding(@evidence)
          @evidence.update_attributes(:update_reason => "all documents deleted", updated_by: current_user.oim_id)
          # update_documents_status(@docs_owner)
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

    def record
      @evidence
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

      @application = @applicant&.application if @application.blank?

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
      # Here 'evidence kind' needs to be a singular association on
      # FinancialAssistance::Applicant which corresponds to something which can
      # embed documents.  The options for what this can be are limited.
      # We should find a better way to do this, and probably limit the values
      # based on the model structure.
      return if @docs_owner.blank?
      return if params[:evidence_kind].blank?
      evidence_kind = params[:evidence_kind].to_s
      return unless ['income_evidence', 'esi_evidence', 'non_esi_evidence', 'local_mec_evidence'].include?(evidence_kind)
      @evidence = case evidence_kind
                  when 'income_evidence'
                    @docs_owner.income_evidence
                  when 'esi_evidence'
                    @docs_owner.esi_evidence
                  when 'non_esi_evidence'
                    @docs_owner.non_esi_evidence
                  when 'local_mec_evidence'
                    @docs_owner.local_mec_evidence
                  end
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
      @evidence.move_to_review!
      @evidence.update_attributes(:update_reason => "document uploaded", updated_by: current_user.oim_id)
      @doc_errors = document.errors.full_messages unless success
      # update_documents_status(@docs_owner)
      @docs_owner.save!
    end

    def get_document(key)
      documents = @evidence.documents

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
      actor = current_user ? current_user.oim_id : "external source or script"
      action = case params[:action]
               when "upload"
                 "Upload #{file_name(file)}"
               when "destroy"
                 "Delete #{file.title}"
               end

      verification_history = Eligibilities::VerificationHistory.new(action: action, updated_by: actor)
      @evidence.verification_histories << verification_history
      @evidence.save!
    end
  end
end
