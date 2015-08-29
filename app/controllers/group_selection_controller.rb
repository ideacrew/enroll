class GroupSelectionController < ApplicationController
  def new
    initialize_common_vars

    if @person.try(:has_active_employee_roles) and !@person.try(:has_active_consumer_role)
      @market_kind = 'shop'
    elsif !@person.try(:has_active_employee_roles) and @person.try(:has_active_consumer_role)
      @market_kind = 'individual'
    else
      @market_kind = params[:market_kind].present? ? params[:market_kind] : ''
    end
  end

  def create
    initialize_common_vars
    keep_existing_plan = params[:commit] == "Keep existing plan"
    @market_kind = params[:market_kind].present? ? params[:market_kind] : 'shop'

    return redirect_to purchase_consumer_profiles_path(change_plan: @change_plan, terminate: 'terminate') if params[:commit] == "Terminate Plan"

    raise "You must select at least one applicant to enroll in the healthcare plan" if params[:family_member_ids].blank?
    family_member_ids = params.require(:family_member_ids).collect() do |index, family_member_id|
      BSON::ObjectId.from_string(family_member_id)
    end

    hbx_enrollment = case @market_kind
                     when 'shop'
                       @coverage_household.household.new_hbx_enrollment_from(
                         employee_role: @employee_role,
                         coverage_household: @coverage_household,
                         benefit_group: @employee_role.benefit_group
                       )
                     when 'individual'
                       @coverage_household.household.new_hbx_enrollment_from(
                         consumer_role: @person.consumer_role,
                         coverage_household: @coverage_household,
                         benefit_package: @benefit_package,
                         qle: @change_plan == 'change_by_qle')
                     end

    hbx_enrollment.plan = @hbx_enrollment.plan if keep_existing_plan and @hbx_enrollment.present?

    hbx_enrollment.hbx_enrollment_members = hbx_enrollment.hbx_enrollment_members.select do |member|
      family_member_ids.include? member.applicant_id
    end

    hbx_enrollment.writing_agent_id = current_user.id
    hbx_enrollment.original_application_type = session[:original_application_type]
    broker_role = current_user.person.broker_role
    hbx_enrollment.broker_agency_profile_id = broker_role.broker_agency_profile_id if broker_role

    if hbx_enrollment.save
      hbx_enrollment.inactive_related_hbxs # FIXME: bad name, but might go away
      if keep_existing_plan
        redirect_to purchase_consumer_profiles_path(change_plan: @change_plan, market_kind: @market_kind, coverage_kind: @coverage_kind)
      elsif @change_plan.present?
        redirect_to insured_plan_shopping_path(:id => hbx_enrollment.id, change_plan: @change_plan, market_kind: @market_kind, coverage_kind: @coverage_kind)
      else
        # FIXME: models should update relationships, not the controller
        hbx_enrollment.benefit_group_assignment.update(hbx_enrollment_id: hbx_enrollment.id) if hbx_enrollment.benefit_group_assignment.present?
        redirect_to insured_plan_shopping_path(:id => hbx_enrollment.id, market_kind: @market_kind, coverage_kind: @coverage_kind)
      end
    else
      raise "You must select the primary applicant to enroll in the healthcare plan"
    end
  rescue Exception => error
    flash[:error] = error.message
    return redirect_to group_selection_new_path(person_id: @person.id, employee_role_id: @employee_role.try(:id), consumer_role_id: @consumer_role.try(:id), change_plan: @change_plan, market_kind: @market_kind)
  end

  private

  def initialize_common_vars
    person_id = params.require(:person_id)
    @person = Person.find(person_id)
    @family = @person.primary_family
    @coverage_household = @family.active_household.immediate_family_coverage_household
    @hbx_enrollment = (@family.latest_household.try(:hbx_enrollments).active || []).last
    if params[:employee_role_id].present?
      emp_role_id = params.require(:employee_role_id)
      @employee_role = @person.employee_roles.detect { |emp_role| emp_role.id.to_s == emp_role_id.to_s }
    else
      @consumer_role = @person.consumer_role
    end
    @change_plan = params[:change_plan].present? ? params[:change_plan] : ''
    @coverage_kind = params[:coverage_kind].present? ? params[:coverage_kind] : 'health'
  end
end
