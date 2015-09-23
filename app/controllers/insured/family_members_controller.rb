class Insured::FamilyMembersController < ApplicationController
  include ApplicationHelper
  include ErrorBubble

  before_action :set_current_person, :set_family
  def index
    set_consumer_bookmark_url
    @type = (params[:employee_role_id].present? && params[:employee_role_id] != 'None') ? "employee" : "consumer"
    if @type == "employee"
      emp_role_id = params.require(:employee_role_id)
      @employee_role = @person.employee_roles.detect { |emp_role| emp_role.id.to_s == emp_role_id.to_s }
    else
      @consumer_role = @person.consumer_role
    end
    @change_plan = params[:change_plan].present? ? 'change_by_qle' : ''
    @change_plan_date = params[:qle_date].present? ? params[:qle_date] : ''

    if params[:qle_id].present?
      qle = QualifyingLifeEventKind.find(params[:qle_id])
      special_enrollment_period = @family.special_enrollment_periods.new(effective_on_kind: params[:effective_on_kind])
      special_enrollment_period.selected_effective_on = Date.strptime(params[:effective_on_date], "%m/%d/%Y") if params[:effective_on_date].present?
      special_enrollment_period.qle_on = Date.strptime(params[:qle_date], "%m/%d/%Y")
      special_enrollment_period.qualifying_life_event_kind = qle
      special_enrollment_period.save
    end
  end

  def new
    @dependent = Forms::FamilyMember.new(:family_id => params.require(:family_id))
    respond_to do |format|
      format.html
      format.js
    end
  end

  def create
    doc_params = params_clean_vlp_documents
    @dependent = Forms::FamilyMember.new(params.require(:dependent).permit!)
    if @dependent.save
      update_vlp_documents(doc_params)
      @created = true
      respond_to do |format|
        format.html { render 'show' }
        format.js { render 'show' }
      end
    else
      update_vlp_documents(doc_params)
      @dependent.addresses = Address.new(@dependent.addresses) if @dependent.addresses.is_a? ActionController::Parameters
      respond_to do |format|
        format.html { render 'new' }
        format.js { render 'new' }
      end
    end
  end

  def destroy
    @dependent = Forms::FamilyMember.find(params.require(:id))
    @dependent.destroy!

    respond_to do |format|
      format.html { render 'index' }
      format.js { render 'destroyed' }
    end
  end

  def show
    @dependent = Forms::FamilyMember.find(params.require(:id))

    respond_to do |format|
      format.html
      format.js
    end
  end

  def edit
    @dependent = Forms::FamilyMember.find(params.require(:id))

    respond_to do |format|
      format.html
      format.js
    end
  end

  def update
    @family = @person.primary_family
    doc_params = params_clean_vlp_documents
    @dependent = Forms::FamilyMember.find(params.require(:id))

    if @dependent.update_attributes(params.require(:dependent)) and update_vlp_documents(doc_params)
      respond_to do |format|
        format.html { render 'show' }
        format.js { render 'show' }
      end
    else
      @dependent.same_with_primary = Forms::FamilyMember.compare_address_with_primary(@dependent.family_member)
      @dependent.addresses = Address.new(@dependent.addresses) if @dependent.addresses.is_a? ActionController::Parameters
      respond_to do |format|
        format.html { render 'edit' }
        format.js { render 'edit' }
      end
    end
  end

private

  def set_family
    @family = @person.try(:primary_family)
  end

  def params_clean_vlp_documents
    if (params[:dependent][:us_citizen] == 'true' and params[:dependent][:naturalized_citizen] == 'false') or (params[:dependent][:us_citizen] == 'false' and params[:dependent][:eligible_immigration_status] == 'false')
      params[:dependent].delete :consumer_role
      return
    end

    return if params[:dependent][:consumer_role].nil? or params[:dependent][:consumer_role][:vlp_documents_attributes].nil?

    if params[:dependent][:us_citizen].eql? 'true'
      params[:dependent][:consumer_role][:vlp_documents_attributes].reject! do |index, doc|
        params[:naturalization_doc_type] != doc[:subject]
      end
    elsif params[:dependent][:eligible_immigration_status].eql? 'true'
      params[:dependent][:consumer_role][:vlp_documents_attributes].reject! do |index, doc|
        params[:immigration_doc_type] != doc[:subject]
      end
    end

    vlp_doc_params = params[:dependent][:consumer_role]
    params[:dependent].delete :consumer_role
    vlp_doc_params
  end

  def update_vlp_documents(vlp_doc_params)
    return true unless vlp_doc_params.present?
    doc_params = vlp_doc_params.permit(:vlp_documents_attributes=> [:subject, :citizenship_number, :naturalization_number,
                                                                    :alien_number, :passport_number, :sevis_id, :visa_number,
                                                                    :receipt_number, :expiration_date, :card_number, :i94_number])
    return true if doc_params[:vlp_documents_attributes].first.nil?
    @vlp_doc_subject = doc_params[:vlp_documents_attributes].first.last[:subject]
    return true if @dependent.family_member.blank?
    dependent_person = @dependent.family_member.person
    document = find_document(dependent_person.consumer_role, @vlp_doc_subject)
    document.update_attributes(doc_params[:vlp_documents_attributes].first.last)
    add_document_errors_to_dependent(@dependent, document)
    return document.errors.blank?
  end
end
