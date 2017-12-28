class ResidentRolePolicy < ApplicationPolicy
  def begin_resident_enrollment?
    return false unless role = user.person.hbx_staff_role
    role.permission.can_complete_resident_application
  end

  def resume_resident_enrollment?
    begin_resident_enrollment?
  end

  def search?
    begin_resident_enrollment?
  end

  def match?
    begin_resident_enrollment?
  end

  def create?
    begin_resident_enrollment?
  end

  def edit?
    begin_resident_enrollment?
  end

  def update?
    begin_resident_enrollment?
  end

  def ridp_bypass?
    begin_resident_enrollment?
  end
  def can_access_resident_application_sub_tab?
    return @user.person.hbx_staff_role.permission.can_access_resident_application_sub_tab if (@user.person && @user.person.hbx_staff_role)
    return false
  end
end
