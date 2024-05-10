class DocumentsController < ApplicationController
  include ActionView::Helpers::TranslationHelper
  include L10nHelper
  before_action :fetch_record, only: [:authorized_download, :cartafact_download]
  before_action :set_document, only: [:destroy, :update]
  before_action :set_verification_type
  before_action :set_person, only: [:enrollment_docs_state, :fed_hub_request, :enrollment_verification, :update_verification_type, :extend_due_date, :update_ridp_verification_type]
  before_action :add_type_history_element, only: [:update_verification_type, :fed_hub_request, :destroy]
  before_action :cartafact_download_params, only: [:cartafact_download]
  respond_to :html, :js

  def authorized_download
    authorize @record, :can_download_document?

    begin
      relation_id = params[:relation_id]
      documents = @record.documents
      uri = documents.find(relation_id).identifier
      send_data Aws::S3Storage.find(uri), get_options(params)
    rescue => e
      redirect_back(fallback_location: root_path, :flash => {error: e.message})
    end
  end

  def cartafact_download
    authorize @record, :can_download_document?

    begin
      result = ::Operations::Documents::Download.call({params: cartafact_download_params.to_h.deep_symbolize_keys, user: current_user})
      if result.success?
        response_data = result.value!
        send_data response_data, get_options(params)
      else
        errors = result.failure
        redirect_back(fallback_location: root_path, :flash => {error: errors[:message]})
      end
    rescue StandardError => e
      Rails.logger.error {"Cartafact Download Error - #{e}"}
      redirect_back(fallback_location: root_path, :flash => {error: e.message})
    end
  end

  def employees_template_download
    authorize current_user, :can_download_employees_template?

    begin
      bucket = env_bucket_name("templates")
      key = EnrollRegistry[:enroll_app].setting(:employees_template_key).item
      uri = "urn:openhbx:terms:v1:file_storage:s3:bucket:#{bucket}##{key}"
      send_data Aws::S3Storage.find(uri), get_options(params)
    rescue StandardError => e
      redirect_back(fallback_location: root_path, :flash => {error: e.message})
    end
  end

  def product_sbc_download
    set_current_person
    authorize @person, :can_download_sbc_documents?

    begin
      sbc_document = fetch_product_sbc_document
      uri = sbc_document.identifier
      send_data Aws::S3Storage.find(uri), get_options(params)
    rescue StandardError => e
      redirect_back(fallback_location: root_path, :flash => {error: e.message})
    end
  end

  def employer_attestation_document_download
    authorize current_user, :can_download_employer_attestation_doc?

    begin
      attestation_document = fetch_employer_profile_attestation_document
      uri = attestation_document&.identifier
      send_data Aws::S3Storage.find(uri), get_options(params)
    rescue StandardError => e
      redirect_back(fallback_location: root_path, :flash => {error: e.message})
    end
  end

  def update_verification_type
    authorize HbxProfile, :can_update_verification_type?

    family_member = FamilyMember.find(params[:family_member_id]) if params[:family_member_id].present?
    update_reason = params[:verification_reason]
    admin_action = params[:admin_action]
    reasons_list = VlpDocument::VERIFICATION_REASONS + VlpDocument::ALL_TYPES_REJECT_REASONS + VlpDocument::CITIZEN_IMMIGR_TYPE_ADD_REASONS
    if (reasons_list).include? (update_reason)
      verification_result = @person.consumer_role.admin_verification_action(admin_action, @verification_type, update_reason)
      @person.save
      message = (verification_result.is_a? String) ? verification_result : "Person verification successfully approved."
      flash_message = { :success => message}
      update_documents_status(family_member) if family_member
    else
      flash_message = { :error => "Please provide a verification reason."}
    end

    respond_to do |format|
      format.html { redirect_back(fallback_location: root_path, :flash => flash_message) }
    end
  end

  def update_ridp_verification_type
    authorize HbxProfile, :can_update_ridp_verification_type?

    ridp_type = params[:ridp_verification_type]
    update_reason = params[:verification_reason]
    admin_action = params[:admin_action]
    if (RidpDocument::VERIFICATION_REASONS + RidpDocument::RETURNING_FOR_DEF_REASONS).include? (update_reason)
      verification_result = @person.consumer_role.admin_ridp_verification_action(admin_action, ridp_type, update_reason, @person)
      message = (verification_result.is_a? String) ? verification_result : "Person verification successfully approved."
      flash_message = { :success => message}
    else
      flash_message = { :error => "Please provide a verification reason."}
    end

    respond_to do |format|
      format.html { redirect_back fallback_location: '/', :flash => flash_message }
    end
  end

  def enrollment_verification
    authorize HbxProfile, :can_verify_enrollment?

    family = @person.primary_family
    if family.active_household.hbx_enrollments.verification_needed.any?
      family.active_household.hbx_enrollments.verification_needed.each(&:evaluate_individual_market_eligiblity)
      family.save!
      respond_to do |format|
        format.html do
          flash[:success] = "Enrollment group was completely verified."
          redirect_back(fallback_location: root_path)
        end
      end
    else
      respond_to do |format|
        format.html do
          flash[:danger] = "Family does not have any active Enrollment to verify."
          redirect_back(fallback_location: root_path)
        end
      end
    end
  end

  def fed_hub_request
    authorize HbxProfile, :can_call_hub?

    request_hash = { person_id: @person.id, verification_type: @verification_type.type_name }
    result = ::Operations::CallFedHub.new.call(request_hash)
    key, message = result.failure? ? result.failure : result.success
    if result.failure?
      @verification_type.fail_type
      @verification_type.add_type_history_element(action: "Hub Request Failed",
                                                  modifier: "System",
                                                  update_reason: "#{@verification_type.type_name} Request Failed due to #{message}")
      ::Operations::Eligibilities::BuildFamilyDetermination.new.call(family: @person.primary_family, effective_date: TimeKeeper.date_of_record)
    end

    respond_to do |format|
      format.html {
        flash[key] = message
        redirect_back(fallback_location: root_path)
      }
      format.js
    end
  end

  def show_docs
    if current_user.has_hbx_staff_role?
      session[:person_id] = params[:person_id]
      set_current_person
      @person.primary_family.active_household.hbx_enrollments.verification_needed.each do |enrollment|
        enrollment.update_attributes(:review_status => "in review")
      end
    end
    redirect_to verification_insured_families_path
  end

  def extend_due_date
    authorize HbxProfile, :can_extend_due_date?

    @family_member = FamilyMember.find(params[:family_member_id])
    enrollment = @family_member.family.enrollments.verification_needed.where(:"hbx_enrollment_members.applicant_id" => @family_member.id).first
    if enrollment.present?
      new_date = @verification_type.verif_due_date + 30.days
      updated = @verification_type.update_attributes(:due_date => new_date)
      if updated
        flash[:success] = "#{@verification_type.type_name} verification due date was extended for 30 days."
        set_min_due_date_on_family
        add_type_history_element
      end
    else
      flash[:danger] = "Family Member does not have any unverified Enrollment to extend verification due date."
    end
    redirect_back(fallback_location: root_path)
  end

  def destroy
    authorize @person, :can_delete_document?

    @document.delete if @verification_type.type_unverified?
    if @document.destroyed?
      @person.save!
      if (@verification_type.vlp_documents - [@document]).empty?
        @person.consumer_role.return_doc_for_deficiency(@verification_type, "all documents needed")
        flash[:danger] = "All documents were deleted. Action needed"
      else
        flash[:success] = "Document deleted."
      end
    else
      flash[:danger] = "Document can not be deleted because type is verified."
    end
    respond_to do |format|
      format.html { redirect_to verification_insured_families_path }
      format.js
    end
  end

  private

  def env_bucket_name(bucket_name)
    aws_env = ENV['AWS_ENV'] || "qa"
    subdomain = EnrollRegistry[:enroll_app].setting(:subdomain).item
    "#{subdomain}-enroll-#{bucket_name}-#{aws_env}"
  end

  def fetch_product_sbc_document
    product_id = params[:product_id]
    product = BenefitMarkets::Products::Product.find(product_id)
    product.sbc_document
  end

  def fetch_employer_profile_attestation_document
    employer_profile = BenefitSponsors::Organizations::Organization.employer_profiles.where(
      :"profiles._id" => BSON::ObjectId.from_string(params[:id])
    ).first.employer_profile

    return unless employer_profile&.employer_attestation.present?

    employer_profile.employer_attestation.employer_attestation_documents.find(params[:document_id])
  end

  def fetch_record
    model_id = params[:model_id]
    model = params[:model].camelize
    model_klass = Document::MODEL_CLASS_MAPPING[model]

    raise "Sorry! Invalid Request" unless model_klass

    @record = model_klass.find(model_id)
  end

  def add_type_history_element
    actor = current_user ? current_user.email : "external source or script"
    action = params[:admin_action] || params[:action]
    action = "Delete #{params[:doc_title]}" if action == "destroy"
    reason = params[:verification_reason]
    if @verification_type
      @verification_type.add_type_history_element(action: action.split('_').join(' '),
                                                  modifier: actor,
                                                  update_reason: reason)
    end
  end

  def get_options(params)
    options = {}
    options[:content_type] = params[:content_type] if params[:content_type]
    options[:filename] = params[:filename] if params[:filename]
    options[:disposition] = params[:disposition] if params[:disposition]
    options
  end

  def authorized_to_download?(owner, documents, document_id)
    return true
    owner.user.has_hbx_staff_role? || documents.find(document_id).present?
  end

  def update_documents_status(family_member)
    family = family_member.family
    family.update_family_document_status!
  end

  def set_document
    set_verification_type
    @document = @verification_type.vlp_documents.where(id: params[:id]).first
    # Handles the specific exception where an ID of a non existing document is called.
    Rails.logger.warn("Unable to find document with ID #{params[:id]} for person with hbx_id: #{@person&.full_name || Person.where(_id: params[:person_id])&.first&.full_name}") if @document.blank?
    error_message = l10n("documents.controller.missing_document_message", contact_center_phone_number: EnrollRegistry[:enroll_app].settings(:contact_center_short_number).item) if @document.blank?
    redirect_back(fallback_location: verification_insured_families_path, :flash => {error: error_message}) if @document.blank?
  end

  def set_person
    @person = Person.find(params[:person_id]) if params[:person_id]
  end

  def set_verification_type
    set_person
    @verification_type = @person.verification_types.active.find(params[:verification_type]) if params[:verification_type]
  end

  def verification_attr
    OpenStruct.new({:determined_at => Time.now,
                    :authority => "hbx"
                   })
  end

  def file_path(file)
    file.tempfile.path
  end

  def file_name(file)
    file.original_filename
  end

  def set_min_due_date_on_family
    family = @family_member.family
    family.update_attributes(min_verification_due_date: family.min_verification_due_date_on_family)
  end

  #permitting required params for cartafact downloads
  def cartafact_download_params
    params.permit(:relation, :relation_id, :model, :model_id, :content_type, :disposition, :file_name, :user)
  end
end
