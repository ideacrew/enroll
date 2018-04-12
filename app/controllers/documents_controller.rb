class DocumentsController < ApplicationController
  before_action :updateable?, except: [:show_docs, :download]
  before_action :set_document, only: [:destroy, :update]
  before_action :set_verification_type
  before_action :set_person, only: [:enrollment_docs_state, :fed_hub_request, :enrollment_verification, :update_verification_type, :extend_due_date]
  before_action :add_type_history_element, only: [:update_verification_type, :fed_hub_request, :destroy]
  respond_to :html, :js

  def download
    bucket = params[:bucket]
    key = params[:key]
    uri = "urn:openhbx:terms:v1:file_storage:s3:bucket:#{bucket}##{key}"
    send_data Aws::S3Storage.find(uri), get_options(params)
  end

  def authorized_download
    begin
      model = params[:model].camelize
      model_id = params[:model_id]
      relation = params[:relation]
      relation_id = params[:relation_id]
      model_object = Object.const_get(model).find(model_id)
      documents = model_object.send(relation.to_sym)
      if authorized_to_download?(model_object, documents, relation_id)
        uri = documents.find(relation_id).identifier
        send_data Aws::S3Storage.find(uri), get_options(params)
      else
       raise "Sorry! You are not authorized to download this document."
      end
    rescue => e
      redirect_to(:back, :flash => {error: e.message})
    end
  end

  def update_verification_type
    update_reason = params[:verification_reason]
    admin_action = params[:admin_action]
    family_member = FamilyMember.find(params[:family_member_id]) if params[:family_member_id].present?
    reasons_list = VlpDocument::VERIFICATION_REASONS + VlpDocument::ALL_TYPES_REJECT_REASONS + VlpDocument::CITIZEN_IMMIGR_TYPE_ADD_REASONS
    if (reasons_list).include? (update_reason)
      verification_result = @person.consumer_role.admin_verification_action(admin_action, @verification_type, update_reason)
      message = (verification_result.is_a? String) ? verification_result : "Person verification successfully approved."
      flash_message = { :success => message}
      update_documents_status(family_member) if family_member
    else
      flash_message = { :error => "Please provide a verification reason."}
    end

    respond_to do |format|
      format.html { redirect_to :back, :flash => flash_message }
    end
  end

  def enrollment_verification
     family = @person.primary_family
     if family.active_household.hbx_enrollments.verification_needed.any?
       family.active_household.hbx_enrollments.verification_needed.each do |enrollment|
         enrollment.evaluate_individual_market_eligiblity
       end
       family.save!
       respond_to do |format|
         format.html {
           flash[:success] = "Enrollment group was completely verified."
           redirect_to :back
         }
       end
     else
       respond_to do |format|
         format.html {
           flash[:danger] = "Family does not have any active Enrollment to verify."
           redirect_to :back
         }
       end
     end
  end

  def fed_hub_request
    if @verification_type.type_name == 'DC Residency'
      @person.consumer_role.invoke_residency_verification!
    else
      @person.consumer_role.redetermine_verification!(verification_attr)
    end
    respond_to do |format|
      format.html {
        hub =  @verification_type.type_name == 'DC Residency' ? 'Local Residency' : 'FedHub'
        flash[:success] = "Request was sent to #{hub}."
        redirect_to :back
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
    @family_member = FamilyMember.find(params[:family_member_id])
    enrollment = @family_member.family.enrollments.verification_needed.where(:"hbx_enrollment_members.applicant_id" => @family_member.id).first
    if enrollment.present?
      add_type_history_element
      if @verification_type.due_date
        new_date = @verification_type.due_date + 30.days
        flash[:success] = "Special verification period was extended for 30 days."
      else
        new_date = TimeKeeper.date_of_record + 30.days
        flash[:success] = "You set special verification period for this Enrollment. Verification due date now is #{new_date.to_date}"
      end
      @verification_type.update_attributes(:due_date => new_date)
      set_min_due_date_on_family
    else
      flash[:danger] = "Family Member does not have any unverified Enrollment to extend verification due date."
    end
    redirect_to :back
  end

  def destroy
    @document.delete if @verification_type.type_unverified?
    if @document.destroyed?
      if (@verification_type.vlp_documents - [@document]).empty?
        @verification_type.update_attributes(:validation_status => "outstanding", :update_reason => "all documents deleted")
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

  private
  def updateable?
    authorize Family, :updateable?
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
    @document = @verification_type.vlp_documents.find(params[:id])
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

  def set_min_due_date_on_family
    family = @family_member.family
    family.update_attributes(min_verification_due_date: family.min_verification_due_date_on_family)
  end
end
