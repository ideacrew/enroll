class UserPolicy < ApplicationPolicy

  def initialize(user, record)
    super
    @family = user.person&.primary_family
  end

  def lockable?
    return false unless role = user.person && user.person.hbx_staff_role
    return false unless role.permission
    role.permission.can_lock_unlock
  end

  def reset_password?
    return false unless role = user.person && user.person.hbx_staff_role
    return false unless role.permission
    role.permission.can_reset_password
  end

  def change_username_and_email?
    return false unless role = user.person && user.person.hbx_staff_role
    role.permission.can_change_username_and_email
  end

  def view_login_history?
    return false unless role = user.person && user.person.hbx_staff_role
    return false unless role.permission
    role.permission.view_login_history
  end

  def can_access_user_account_tab?
    return false unless user.person && (role = user.person.hbx_staff_role)
    return false unless role.permission
    role.permission.can_access_user_account_tab
  end

  def view?
    user.present?
  end

  def new?
    view?
  end

  def create?
    view?
  end

  # rubocop:disable Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity
  def can_download_sbc_documents?
    return true if individual_market_primary_family_member?
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
  # rubocop:enable Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity


  def can_download_employees_template?
    return false unless account_holder_person
    return true if account_holder_person.has_active_employer_staff_role?
    return true if shop_market_admin?
    return true if account_holder_person.broker_role&.active?
    return true if account_holder_person.broker_agency_staff_roles&.active
    return true if account_holder_person.active_general_agency_staff_roles.present?
  end

  def can_download_employer_attestation_doc?
    can_download_employees_template?
  end
end
