class Employers::EmployerAttestationsController < ApplicationController

  before_action :find_employer, except: [:new]
  before_action :check_hbx_staff_role, only: [:update, :edit, :accept, :reject]

  def show
  end

  def edit
    @documents = @employer_profile.employer_attestation.employer_attestation_documents
    @element_to_replace_id = params[:employer_actions_id]

    respond_to do |format|
      format.js { render "edit" }
    end
  end

  def new
    @document = Document.new
    respond_to do |format|
      format.js
    end
  end

  def verify_attestation
    attestation = @employer_profile.employer_attestation
    @document = attestation.employer_attestation_documents.find(params[:employer_attestation_id])
  end

  def create
    @errors = []
    if params[:file]
      @employer_profile.build_employer_attestation unless @employer_profile.employer_attestation
      file = params[:file]
      doc_uri = Aws::S3Storage.save(file.tempfile.path, 'attestations')
      if doc_uri.present?
        attestation_document = @employer_profile.employer_attestation.employer_attestation_documents.new
        success = attestation_document.update_attributes({:identifier => doc_uri, :subject => file.original_filename, :title=>file.original_filename, :size => file.size, :format => "application/pdf"})
        errors = attestation_document.errors.full_messages unless success

        if errors.blank? && @employer_profile.save
          @employer_profile.employer_attestation.submit! if @employer_profile.employer_attestation.may_submit?
          flash[:notice] = "File Saved"
        else
          flash[:error] = "Could not save file. " + errors.join(". ")
        end
      else
        flash[:error] = "Could not save file"
      end
    else
      flash[:error] = "Please upload file"
    end

    redirect_to(:back)
  end

  def update
    attestation = @employer_profile.employer_attestation
    document = attestation.employer_attestation_documents.find(params[:employer_attestation_id])

    if document.present?
      if [:info_needed, :pending].include?(params[:status].to_sym)
        document.reject! if document.may_reject?
        attestation.set_pending! if params[:status].to_sym == :info_needed && attestation.may_set_pending?
        document.add_reason_for_rejection(params)
      elsif params[:status].to_sym == :accepted
        document.accept! if document.may_accept?
      end

      flash[:notice] = "Employer attestation updated successfully"
    else
      flash[:error] = "Failed: Unable to find attestation document."
    end

    redirect_to exchanges_hbx_profiles_path+'?tab=documents'
  end

  def authorized_download
    begin
      documents = @employer_profile.employer_attestation.employer_attestation_documents
      if authorized_to_download?
        uri = documents.find(params[:employer_attestation_id]).identifier
        send_data Aws::S3Storage.find(uri), get_options(params)
      else
       raise "Sorry! You are not authorized to download this document."
      end
    rescue => e
      redirect_to(:back, :flash => {error: e.message})
    end
  end

  private

  def authorized_to_download?
    true
  end

  def get_options(params)
    options = {}
    options[:content_type] = params[:content_type] if params[:content_type]
    options[:filename] = params[:filename] if params[:filename]
    options[:disposition] = params[:disposition] if params[:disposition]
    options
  end

  def find_employer
    if params[:employer_attestation_id].present?
      org = Organization.where(:"employer_profile.employer_attestation.employer_attestation_documents._id" => BSON::ObjectId.from_string(params[:employer_attestation_id])).first
      @employer_profile = org.employer_profile
    elsif params[:id].present?
      @employer_profile = EmployerProfile.find(params[:id])
    else
      @employer_profile = Organization.where(:legal_name => params["document"]["creator"]).first.try(:employer_profile)
    end
    render file: 'public/404.html', status: 404 if @employer_profile.blank?
  end

  def check_hbx_staff_role
    if !current_user.has_hbx_staff_role?
      redirect_to root_path, :flash => { :error => "You must be an HBX staff member" }
    end
  end
end
