class Employers::EmployerAttestationsController < ApplicationController

  before_action :find_employer, except: [:autocomplete_organization_legal_name, :index, :new]
  before_action :check_hbx_staff_role, only: [:update]

  autocomplete :organization, :legal_name, :full => true, :scopes => [:all_employer_profiles]

  def show

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
        success = attestation_document.update_attributes({:identifier => doc_uri, :subject => file.original_filename, :title=>file.original_filename})
        @errors = attestation_document.errors.full_messages unless success

        if @employer_profile.save
          @employer_profile.employer_attestation.submit! if @employer_profile.employer_attestation.may_submit?
          flash[:notice] = "File Saved"
        else
          flash[:error] = "Could not save file. " + @errors.join(". ")
          redirect_to(:back)
          return
        end
      else
        flash[:error] = "Could not save file"
      end
    end
  end

  def update

  end

  private

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
