class HbxProfilePolicy < ApplicationPolicy

  def edit_aptc_csr?
    staff_can_edit_aptc?
  end

  def calculate_aptc_csr?
    edit_aptc_csr?
  end

  def oe_extendable_applications?
    staff_can_extend_open_enrollment?
  end

  def oe_extended_applications?
    staff_can_extend_open_enrollment?
  end

  def edit_open_enrollment?
    staff_can_extend_open_enrollment?
  end

  def extend_open_enrollment?
    staff_can_extend_open_enrollment?
  end

  def close_extended_open_enrollment?
    staff_can_extend_open_enrollment?
  end

  def new_benefit_application?
    staff_can_create_benefit_application?
  end

  def create_benefit_application?
    staff_can_create_benefit_application?
  end

  def edit_fein?
    staff_can_change_fein?
  end

  def update_fein?
    staff_can_change_fein?
  end

  def binder_paid?
    staff_modify_admin_tabs?
  end

  def new_secure_message?
    staff_can_send_secure_message?
  end

  def create_send_secure_message?
    staff_can_send_secure_message?
  end

  def disable_ssn_requirement?
    staff_can_update_ssn?
  end

  def generate_invoice?
    staff_modify_employer?
  end

  def edit_force_publish?
    staff_can_force_publish?
  end

  def force_publish?
    staff_can_force_publish?
  end

  def employer_invoice?
    index?
  end

  def employer_datatable?
    index?
  end

  def index?
    return true if individual_market_admin?
    return true if shop_market_admin?

    false
  end

  def staff_index?
    index?
  end

  # rubocop:disable Metrics/CyclomaticComplexity
  # Determines if the current user has permission to access the assister index.
  # The user can access the assister index if they are a primary family member,
  # an admin, an active associated broker staff, or an active associated broker in the individual market,
  # the ACA Shop market, the Non-ACA Fehb market, or the coverall market.
  #
  # @return [Boolean] Returns true if the user has permission to access the assister index, false otherwise.
  # @note This method checks for permissions across multiple markets and roles.
  def assister_index?
    # Fall back on a family if it exists for the current user.
    @family = account_holder_family
    return true if individual_market_primary_family_member?
    return true if individual_market_non_ridp_primary_family_member?
    return true if individual_market_admin?
    return true if active_associated_individual_market_family_broker_staff?
    return true if active_associated_individual_market_family_broker?

    return true if shop_market_primary_family_member?
    return true if shop_market_admin?
    return true if active_associated_shop_market_family_broker?
    return true if active_associated_shop_market_general_agency?

    return true if fehb_market_primary_family_member?
    return true if fehb_market_admin?
    return true if active_associated_fehb_market_family_broker?
    return true if active_associated_fehb_market_general_agency?

    return true if coverall_market_primary_family_member?
    return true if coverall_market_admin?
    return true if active_associated_coverall_market_family_broker?

    false
  end
  # rubocop:enable Metrics/CyclomaticComplexity

  def family_index?
    return true if index?
    return true if user.person&.csr_role&.cac

    false
  end

  def family_index_dt?
    index?
  end

  def identity_verification?
    index?
  end

  def user_account_index?
    staff_can_access_user_account_tab?
  end

  def outstanding_verification_dt?
    index?
  end

  def hide_form?
    staff_can_add_sep?
  end

  def add_sep_form?
    staff_can_add_sep?
  end

  def show_sep_history?
    staff_can_view_sep_history?
  end

  # rubocop:disable Naming/AccessorMethodName
  def get_user_info?
    index?
  end
  # rubocop:enable Naming/AccessorMethodName

  def update_effective_date?
    staff_can_add_sep?
  end

  def calculate_sep_dates?
    staff_can_add_sep?
  end

  def add_new_sep?
    staff_can_add_sep?
  end

  def cancel_enrollment?
    staff_can_cancel_enrollment?
  end

  def update_cancel_enrollment?
    staff_can_cancel_enrollment?
  end

  def terminate_enrollment?
    staff_can_terminate_enrollment?
  end

  def update_terminate_enrollment?
    staff_can_terminate_enrollment?
  end

  def drop_enrollment_member?
    staff_can_drop_enrollment_members?
  end

  def update_enrollment_member_drop?
    staff_can_drop_enrollment_members?
  end

  def view_enrollment_to_update_end_date?
    staff_change_enrollment_end_date?
  end

  def update_enrollment_terminated_on_date?
    staff_change_enrollment_end_date?
  end

  def broker_agency_index?
    index?
  end

  def general_agency_index?
    index?
  end

  def configuration?
    staff_view_the_configuration_tab?
  end

  def view_terminated_hbx_enrollments?
    index?
  end

  def reinstate_enrollment?
    staff_can_reinstate_enrollment?
  end

  def edit_dob_ssn?
    staff_can_update_ssn?
  end

  def verify_dob_change?
    staff_can_update_ssn?
  end

  def update_dob_ssn?
    staff_can_update_ssn?
  end

  def new_eligibility?
    staff_can_add_pdc?
  end

  def process_eligibility?
    staff_can_add_pdc?
  end

  def create_eligibility?
    staff_can_add_pdc?
  end

  def show?
    index?
  end

  def inbox?
    index?
  end

  def set_date?
    staff_can_submit_time_travel_request?
  end

  def aptc_csr_family_index?
    index?
  end

  def update_setting?
    staff_modify_admin_tabs?
  end

  def confirm_lock?
    staff_can_lock_unlock?
  end

  def lockable?
    staff_can_lock_unlock?
  end

  def reset_password?
    staff_can_reset_password?
  end

  def confirm_reset_password?
    staff_can_reset_password?
  end

  def change_username_and_email?
    staff_can_change_username_and_email?
  end

  def confirm_change_username_and_email?
    staff_can_change_username_and_email?
  end

  def login_history?
    staff_view_login_history?
  end

  def hop_to_date?
    can_submit_time_travel_request?
  end

  # Acts as the entire Pundit Policy for app/controllers/translations_controller.rb
  def can_view_or_change_translations?
    user_hbx_staff_role&.permission&.name == "super_admin"
  end

  def view_admin_tabs?
    role = user_hbx_staff_role
    return false unless role
    role.permission.view_admin_tabs
  end

  def modify_admin_tabs?
    role = user_hbx_staff_role
    return false unless role
    role.permission.modify_admin_tabs
  end

  def view_the_configuration_tab?
    role = user_hbx_staff_role
    return false unless role
    role.permission.view_the_configuration_tab
  end

  def can_submit_time_travel_request?
    role = user_hbx_staff_role
    return false unless role
    return false unless role.permission.name == "super_admin"
    role.permission.can_submit_time_travel_request
  end

  def send_broker_agency_message?
    role = user_hbx_staff_role
    return false unless role
    role.permission.send_broker_agency_message
  end

  def approve_broker?
    role = user_hbx_staff_role
    return false unless role
    role.permission.approve_broker
  end

  def approve_ga?
    role = user_hbx_staff_role
    return false unless role
    role.permission.approve_ga
  end

  def can_extend_open_enrollment?
    role = user_hbx_staff_role
    return false unless role
    role.permission.can_extend_open_enrollment
  end

  def can_modify_plan_year?
    return true unless (role = user.person.hbx_staff_role)

    role.permission.can_modify_plan_year
  end

  def can_create_benefit_application?
    role = user_hbx_staff_role
    return false unless role
    role.permission.can_create_benefit_application?
  end

  def can_change_fein?
    role = user_hbx_staff_role
    return false unless role
    role.permission.can_change_fein
  end

  def can_force_publish?
    role = user_hbx_staff_role
    return false unless role
    role.permission.can_force_publish
  end

  def can_access_age_off_excluded?
    role = user_hbx_staff_role
    return false unless role
    role.permission.can_access_age_off_excluded
  end

  def can_send_secure_message?
    role = user_hbx_staff_role
    return false unless role
    role.permission.can_send_secure_message
  end

  def employer_index?
    index?
  end

  def new?
    @user.has_role? :hbx_staff
  end

  def edit?
    if @user.has_role?(:hbx_staff)
      @record.id == @user.try(:person).try(:hbx_staff_role).try(:hbx_profile).try(:id)
    else
      false
    end
  end

  def create?
    new?
  end

  def update?
    edit?
  end

  def destroy?
    edit?
  end

  def can_add_sep?
    role = user_hbx_staff_role
    return false unless role
    role.permission.can_add_sep
  end

  def access_identity_verification_sub_tab?
    return @user.person.hbx_staff_role.permission.can_access_identity_verification_sub_tab if (@user.person && @user.person.hbx_staff_role)
    return false
  end

  def access_outstanding_verification_sub_tab?
    return @user.person.hbx_staff_role.permission.can_access_outstanding_verification_sub_tab if (@user.person && @user.person.hbx_staff_role)
    return false
  end

  def can_access_accept_reject_identity_documents?
    return @user.person.hbx_staff_role.permission.can_access_accept_reject_identity_documents if (@user.person && @user.person.hbx_staff_role)
    return false
  end

  def can_access_accept_reject_paper_application_documents?
    return @user.person.hbx_staff_role.permission.can_access_accept_reject_paper_application_documents if (@user.person && @user.person.hbx_staff_role)
    return false
  end

  def can_delete_identity_application_documents?
    return @user.person.hbx_staff_role.permission.can_delete_identity_application_documents if (@user.person && @user.person.hbx_staff_role)
    return false
  end

  def can_access_user_account_tab?
    return @user.person.hbx_staff_role.permission.can_access_user_account_tab if @user&.person && @user.person.hbx_staff_role

    false
  end

  def can_add_pdc?
    role = user_hbx_staff_role
    return false unless role

    role.permission.can_add_pdc
  end

  def can_call_hub?
    staff_can_call_hub?
  end

  def can_verify_enrollment?
    individual_market_admin?
  end

  def can_update_ridp_verification_type?
    individual_market_admin?
  end

  def can_extend_due_date?
    individual_market_admin?
  end

  def can_update_verification_type?
    individual_market_admin?
  end

  def can_edit_osse_eligibility?
    role = user_hbx_staff_role
    return false unless role
    role.permission.can_edit_osse_eligibility
  end

  def can_view_osse_eligibility?
    role = user_hbx_staff_role
    true if role
  end

  def can_view_audit_log?
    role = user_hbx_staff_role
    return false unless role
    role.permission.can_view_audit_log
  end

  def dry_run_dashboard?
    individual_market_admin?
  end

  private

  def user_hbx_staff_role
    person = user.person
    return nil unless person
    person.hbx_staff_role
  end
end
