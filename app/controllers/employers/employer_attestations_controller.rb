class Employers::EmployerAttestationsController < ApplicationController

  before_action :find_employer, except: [:autocomplete_organization_legal_name, :index, :new]
  before_action :check_hbx_staff_role, only: [:update, :edit, :accept, :reject]

  autocomplete :organization, :legal_name, :full => true, :scopes => [:all_employer_profiles]

  def show
  end

  def edit
    # @datatable = Effective::Datatables::DocumentDatatable.new({employer_profile_id: params[:id]})
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

  def create
    @errors = []
    if params[:file]
      @employer_profile.build_employer_attestation unless @employer_profile.employer_attestation
      file = params[:file]
      doc_uri = Aws::S3Storage.save(file.tempfile.path, 'attestations')
      if doc_uri.present?
        attestation_document = @employer_profile.employer_attestation.employer_attestation_documents.new
        success = attestation_document.update_attributes({:identifier => doc_uri, :subject => file.original_filename, :title=>file.original_filename, :size => file.size})
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
    attestation_doc = attestation.employer_attestation_documents.find(params[:attestation_doc_id])

    if params[:status] == 'rejected'
      attestation_doc.reject! if attestation_doc.may_reject?
      reason = params[:reason_for_rejection] == "nil"? params[:other_reason] : params[:reason_for_rejection]
      attestation_doc.update(reason_for_rejection: reason)
      attestation.make_pending! if attestation.may_make_pending?
      flash[:notice] = "Employer attestation document is rejected."
    elsif params[:status] == 'accepted'
      attestation_doc.accept! if attestation_doc.may_accept?
      attestation.approve! if attestation.may_approve?
      flash[:notice] = "Employer attestation document is approved."
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
    if params[:id].present?
      @employer_profile = EmployerProfile.find(params[:id])
    else
      @employer_profile = Organization.where(:legal_name => params["document"]["creator"]).first.try(:employer_profile)
    end
    render file: 'public/404.html', status: 404 if @employer_profile.blank?
  end

  def check_hbx_staff_role
    unless current_user.has_hbx_staff_role?
      redirect_to root_path, :flash => { :error => "You must be an HBX staff member" }
    end
  end


end
