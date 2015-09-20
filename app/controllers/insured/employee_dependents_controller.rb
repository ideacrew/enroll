class Insured::EmployeeDependentsController < ApplicationController
  include ApplicationHelper

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
    doc_params = params_clean_vlp_documents
    @family = @person.primary_family
    @dependent = Forms::FamilyMember.find(params.require(:id))

    if @dependent.update_attributes(params.require(:dependent))
      update_vlp_documents(doc_params)
      respond_to do |format|
        format.html { render 'show' }
        format.js { render 'show' }
      end
    else
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
    return unless vlp_doc_params.present?
    doc_params = vlp_doc_params.permit(:vlp_documents_attributes=> [:subject, :citizenship_number, :naturalization_number,
                                                                    :alien_number, :passport_number, :sevis_id, :visa_number,
                                                                    :receipt_number, :expiration_date, :card_number, :i94_number])
    return if doc_params[:vlp_documents_attributes].first.nil?
    dependent_person = @dependent.family_member.person
    document = find_document(dependent_person.consumer_role, doc_params[:vlp_documents_attributes].first.last[:subject])
    document.update_attributes(doc_params[:vlp_documents_attributes].first.last)
    document.save
  end
end
