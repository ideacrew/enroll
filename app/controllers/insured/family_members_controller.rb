class Insured::FamilyMembersController < ApplicationController
  include ApplicationHelper
  include ErrorBubble
  include VlpDoc

  before_action :set_current_person, :set_family
  def index
    set_bookmark_url
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
      special_enrollment_period.qualifying_life_event_kind = qle
      special_enrollment_period.qle_on = Date.strptime(params[:qle_date], "%m/%d/%Y")
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
    @dependent = Forms::FamilyMember.new(params.require(:dependent).permit!)
    consumer_role = @dependent.family_member.try(:person).try(:consumer_role)
    if @dependent.save
      update_vlp_documents(consumer_role, 'dependent', @dependent)
      @created = true
      respond_to do |format|
        format.html { render 'show' }
        format.js { render 'show' }
      end
    else
      update_vlp_documents(consumer_role, 'dependent', @dependent)
      init_address_for_dependent
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
    if @dependent.try(:naturalized_citizen) or @dependent.try(:eligible_immigration_status)
      @vlp_doc_subject = @dependent.family_member.person.consumer_role.try(:vlp_documents).try(:last).try(:subject)
    end

    respond_to do |format|
      format.html
      format.js
    end
  end

  def update
    @dependent = Forms::FamilyMember.find(params.require(:id))
    consumer_role = @dependent.family_member.try(:person).try(:consumer_role)

    if @dependent.update_attributes(params.require(:dependent)) and update_vlp_documents(consumer_role, 'dependent', @dependent)
      respond_to do |format|
        format.html { render 'show' }
        format.js { render 'show' }
      end
    else
      init_address_for_dependent
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

  def init_address_for_dependent
    if @dependent.same_with_primary == "true"
      @dependent.addresses = Address.new(kind: 'home')
    elsif @dependent.addresses.is_a? ActionController::Parameters
      @dependent.addresses = Address.new(@dependent.addresses.try(:permit!))
    end
  end
end
