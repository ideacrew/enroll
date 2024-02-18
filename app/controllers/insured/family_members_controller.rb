# frozen_string_literal: true

class Insured::FamilyMembersController < ApplicationController
  include VlpDoc
  include ApplicationHelper
  include ::L10nHelper

  before_action :dependent_person_params, only: [:create, :update]
  before_action :set_current_person
  before_action :set_dependent_and_family, only: [:destroy, :show, :edit, :update]
  before_action :set_cache_headers, only: [:edit, :new]

  rescue_from ActionController::InvalidAuthenticityToken, :with => :bad_token_due_to_session_expired

  def index
    set_bookmark_url
    set_admin_bookmark_url(insured_family_members_path)
    # There was an error where choosing a shop sep would eventually bring them to a @type == 'consumer'
    @type = if params[:qle_id].present?
              market_kind = QualifyingLifeEventKind.find(params[:qle_id]).market_kind
              market_kind == 'individual' ? 'consumer' : 'employee'
            elsif params[:employee_role_id].present? && params[:employee_role_id] != 'None'
              "employee"
            else
              "consumer"
            end
    if params[:resident_role_id].present? && params[:resident_role_id]
      @type = "resident"
      @resident_role = ResidentRole.find(params[:resident_role_id])
      @family = @resident_role.person.primary_family
      # Why are we passing current_user? Isn't it supposed to be the actual family this is on
      broker_role_id = @resident_role.person.broker_role.try(:id)
      @family.hire_broker_agency(broker_role_id)
      redirect_to resident_index_insured_family_members_path(:resident_role_id => @resident_role.id, :change_plan => params[:change_plan], :qle_date => params[:qle_date], :qle_id => params[:qle_id],
                                                             :effective_on_kind => params[:effective_on_kind], :qle_reason_choice => params[:qle_reason_choice], :commit => params[:commit])
    end

    if @type == "employee"
      emp_role_id = params[:employee_role_id].present? ? params.require(:employee_role_id) : nil
      @employee_role = if emp_role_id.present?
                         @person.employee_roles.detect { |emp_role| emp_role.id.to_s == emp_role_id.to_s }
                       else
                         @person.employee_roles.detect { |emp_role| emp_role.is_active == true }
                       end
      @family = @person.primary_family
    elsif @type == "consumer"
      @consumer_role = @person.consumer_role

      # This controller assumes the user accessing this page will NOT be an admin
      # The logic previously present here has been moved to a method only called _if_ @consumer_role is not nil
      update_family_broker_agency if @consumer_role
    end

    @family = Family.find(params[:family_id]) if params[:family_id]
    authorize_family_access

    @change_plan = params[:change_plan].present? ? 'change_by_qle' : ''
    @change_plan_date = params[:qle_date].present? ? params[:qle_date] : ''

    if params[:sep_id].present?
      @sep = @family.special_enrollment_periods.find(params[:sep_id])
      @qle = QualifyingLifeEventKind.find(params[:qle_id])
      @change_plan = 'change_by_qle'
      @change_plan_date = @sep.qle_on
    elsif params[:qle_id].present? && !params[:shop_for_plan]

      qle = QualifyingLifeEventKind.find(params[:qle_id])
      special_enrollment_period = @family.special_enrollment_periods.new(effective_on_kind: params[:effective_on_kind])
      special_enrollment_period.selected_effective_on = Date.strptime(params[:effective_on_date], "%m/%d/%Y") if params[:effective_on_date].present?
      special_enrollment_period.qualifying_life_event_kind = qle
      special_enrollment_period.qle_on = Date.strptime(params[:qle_date], "%m/%d/%Y")
      special_enrollment_period.market_kind = qle.market_kind == "individual" ? "ivl" : qle.market_kind
      special_enrollment_period.qle_answer = params[:qle_reason_choice] if params[:qle_reason_choice].present?
      special_enrollment_period.save
      @market_kind = qle.market_kind
    end
    @market_kind = params[:market_kind] if params[:market_kind].present?
    if request.referer.present?
      @prev_url_include_intractive_identity = request.referer.include?("interactive_identity_verifications")
      @prev_url_include_consumer_role_id = request.referer.include?("consumer_role_id")
    else
      @prev_url_include_intractive_identity = false
      @prev_url_include_consumer_role_id = false
    end

    set_view_person
  end

  def new
    family_id = params.require(:family_id)
    @family = Family.find(family_id)
    authorize_family_access

    @dependent = ::Forms::FamilyMember.new(:family_id => family_id)
    respond_to do |format|
      format.html
      format.js
    end

    set_view_person
  end

  def create
    @family = Family.find(params[:dependent][:family_id])
    authorize_family_access

    @dependent = ::Forms::FamilyMember.new(params[:dependent].merge({skip_consumer_role_callbacks: true}))
    @address_errors = validate_address_params(params)

    if @family.primary_applicant.person.resident_role?
      if @address_errors.blank? && @dependent.save
        @created = true
        respond_to do |format|
          format.html { render 'show_resident' }
          format.js { render 'show_resident' }
        end
      else
        init_address_for_dependent
        respond_to do |format|
          format.html { render 'new_resident_dependent' }
          format.js { render 'new_resident_dependent' }
        end
      end
      return
    end
    if @address_errors.blank? && @dependent.save && update_vlp_documents(consumer_role_for_create(@dependent), 'dependent', @dependent)
      active_family_members_count = @family.active_family_members.count
      household = @family.active_household
      immediate_household_members_count = household.immediate_family_coverage_household.coverage_household_members.count
      extended_family_members_count = household.extended_family_coverage_household.coverage_household_members.count
      Rails.logger.info("In FamilyMembersController create action #{params}, #{@family.inspect}") unless active_family_members_count == immediate_household_members_count + extended_family_members_count
      @created = true
      consumer_role = @dependent.family_member.try(:person).try(:consumer_role)
      fire_consumer_roles_create_for_vlp_docs(consumer_role) if consumer_role
      respond_to do |format|
        format.html { render 'show' }
        format.js { render 'show' }
      end
    else
      @vlp_doc_subject = get_vlp_doc_subject_by_consumer_role(@dependent.family_member.try(:person).try(:consumer_role))
      init_address_for_dependent
      respond_to do |format|
        format.html { render 'new' }
        format.js { render 'new' }
      end
    end
  end

  def destroy
    @dependent.destroy!
    active_family_members_count = @family.active_family_members&.count
    household = @family.active_household
    immediate_household_members_count = household.immediate_family_coverage_household.coverage_household_members.count
    extended_family_members_count = household.extended_family_coverage_household.coverage_household_members.count
    Rails.logger.info("In FamilyMembersController Destroy action #{params}, #{@family.inspect}") unless active_family_members_count == immediate_household_members_count + extended_family_members_count
    respond_to do |format|
      format.html { render 'index' }
      format.js { render 'destroyed' }
    end
  end

  def show
    respond_to do |format|
      format.html
      format.js
    end
    set_view_person
  end

  def edit
    consumer_role = @dependent.family_member.try(:person).try(:consumer_role)
    @vlp_doc_subject = get_vlp_doc_subject_by_consumer_role(consumer_role) if consumer_role.present?

    respond_to do |format|
      format.html
      format.js
    end
    set_view_person
  end

  def update
    @dependent.skip_consumer_role_callbacks = true
    @address_errors = validate_address_params(params)

    if @dependent.family_member.try(:person).present? && @dependent.family_member.try(:person).is_resident_role_active?
      if @address_errors.blank? && @dependent.update_attributes(params[:dependent])
        respond_to do |format|
          format.html { render 'show_resident' }
          format.js { render 'show_resident' }
        end
      else
        init_address_for_dependent
        respond_to do |format|
          format.html { render 'edit_resident_dependent' }
          format.js { render 'edit_resident_dependent' }
        end
      end
      return
    end
    consumer_role = @dependent.family_member.try(:person).try(:consumer_role)
    original_applying_for_coverage = consumer_role.present? ? consumer_role.is_applying_coverage : nil
    if @address_errors.blank? && @dependent.update_attributes(dependent_person_params[:dependent]) && update_vlp_documents(consumer_role, 'dependent', @dependent)
      active_family_members_count = @family.active_family_members.count
      household = @family.active_household
      immediate_household_members_count = household&.immediate_family_coverage_household&.coverage_household_members&.count
      extended_family_members_count = household.extended_family_coverage_household.coverage_household_members.count
      Rails.logger.info("In FamilyMembersController Update action #{params}, #{@family.inspect}") unless active_family_members_count == immediate_household_members_count + extended_family_members_count
      consumer_role = @dependent.family_member.try(:person).try(:consumer_role)
      if consumer_role.present? && !params[:dependent][:is_applying_coverage].nil?
        consumer_role.update_attribute(
          :is_applying_coverage,
          params[:dependent][:is_applying_coverage]
        )
      end
      fire_consumer_roles_update_for_vlp_docs(consumer_role, original_applying_for_coverage)
      respond_to do |format|
        format.html { render 'show' }
        format.js { render 'show' }
      end
    else
      @vlp_doc_subject = get_vlp_doc_subject_by_consumer_role(consumer_role) if consumer_role.present?
      init_address_for_dependent
      respond_to do |format|
        format.html { render 'edit' }
        format.js { render 'edit' }
      end
    end
  end

  def resident_index
    @resident_role = ResidentRole.find(params[:resident_role_id])
    @family = @resident_role.person.primary_family
    authorize_family_access

    set_bookmark_url
    set_admin_bookmark_url(resident_index_insured_family_members_path)

    @change_plan = params[:change_plan].present? ? 'change_by_qle' : ''
    @change_plan_date = params[:qle_date].present? ? params[:qle_date] : ''

    if params[:qle_id].present?
      qle = QualifyingLifeEventKind.find(params[:qle_id])
      # TODO: How do we know @family is getting set here
      special_enrollment_period = @family.special_enrollment_periods.new(effective_on_kind: params[:effective_on_kind])
      @effective_on_date = special_enrollment_period.selected_effective_on = Date.strptime(params[:effective_on_date], "%m/%d/%Y") if params[:effective_on_date].present?
      special_enrollment_period.qualifying_life_event_kind = qle
      special_enrollment_period.qle_on = Date.strptime(params[:qle_date], "%m/%d/%Y")
      special_enrollment_period.qle_answer = params[:qle_reason_choice] if params[:qle_reason_choice].present?
      special_enrollment_period.save
      @market_kind = "coverall"
    end

    if request.referer.present?
      @prev_url_include_intractive_identity = request.referer.include?("interactive_identity_verifications")
      @prev_url_include_consumer_role_id = request.referer.include?("consumer_role_id")
    else
      @prev_url_include_intractive_identity = false
      @prev_url_include_consumer_role_id = false
    end
  end

  def new_resident_dependent
    family_id = params.require(:family_id)
    @family = Family.find(family_id)
    authorize_family_access

    @dependent = ::Forms::FamilyMember.new(:family_id => family_id)
    respond_to do |format|
      format.html
      format.js
    end
  end

  def edit_resident_dependent
    family_id = params.require(:id)
    @family = Family.find(family_id)
    authorize_family_access

    @dependent = ::Forms::FamilyMember.find(family_id)
    respond_to do |format|
      format.html
      format.js
    end
  end

  def show_resident_dependent
    family_id = params.require(:id)
    @family = Family.find(family_id)
    authorize_family_access

    @dependent = ::Forms::FamilyMember.find(family_id)
    respond_to do |format|
      format.html
      format.js
    end
  end

  private

  def update_family_broker_agency
    @family = @consumer_role.person.primary_family
    broker_role_id = @consumer_role.person.broker_role.try(:id)
    @family.hire_broker_agency(broker_role_id)
  end

  def consumer_role_for_create(dependent)
    consumer_role = dependent.family_member.try(:person).try(:consumer_role)
    consumer_role.skip_consumer_role_callbacks = true if consumer_role.present?
    consumer_role
  end

  def dependent_person_params
    params.permit(:dependent => {})
  end

  def init_address_for_dependent
    if @dependent.same_with_primary == "true"
      @dependent.addresses = [Address.new(kind: 'home'), Address.new(kind: 'mailing')]
    elsif @dependent.addresses.is_a? ActionController::Parameters
      addresses = []
      @dependent.addresses.each do |_k, address|
        addresses << Address.new(address.permit!)
      end
      @dependent.addresses = addresses
    end
  end

  def validate_address_params(params)
    return [] if params[:dependent][:same_with_primary] == 'true'

    errors_array = []
    clean_address_params = params[:dependent][:addresses]&.reject{ |_key, value| value[:address_1].blank? && value[:city].blank? && value[:state].blank? && value[:zip].blank? }
    return [] if clean_address_params.blank?
    param_indexes = clean_address_params.keys.compact
    param_indexes.each do |param_index|
      permitted_address_params = clean_address_params.require(param_index).permit(:address_1, :address_2, :city, :kind, :state, :zip)
      result = Validators::AddressContract.new.call(permitted_address_params.to_h)
      errors_array << result.errors.to_h if result.failure?
    end
    errors_array
  end

  def set_dependent_and_family
    @dependent = ::Forms::FamilyMember.find(params.require(:id))
    @family = Family.find(@dependent.family_id)

    authorize_family_access
  end

  def authorize_family_access
    # We're using FamilyPolicy method here because FamilyMember is an extension of Family
    # All users/roles with the permissions to alter a Family should have the same permissions on the FamilyMember
    # While using a single :show? method in the family policy isn't ideal, it does cover a variety of unforseen edge cases that could emerge when determining a user role

    authorize @family, :show?
  end

  def set_view_person
    # The unfortunate inclusion of this method on all read-related actions (:index, :show, :new, :edit)
    # is being added to the last line of those methods because this controller was not designed to handle
    # an admin accessing family members on an unrelated user account

    @person = @family.primary_person if @person != @family.primary_person
  end
end
