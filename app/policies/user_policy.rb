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

  def can_download_employees_template?
    return false unless account_holder_person
    return true if account_holder_person.has_active_employer_staff_role?
    return true if shop_market_admin?
    return true if account_holder_person.broker_role&.active?
    return true if account_holder_person.broker_agency_staff_roles&.active.present?
    return true if account_holder_person.active_general_agency_staff_roles.present?

    false
  end

  def can_download_employer_attestation_doc?
    can_download_employees_template?
  end
end
