class AdminPolicy < ApplicationPolicy

  def modify_admin_tabs?
    user.person.hbx_staff_role.permission.modify_admin_tabs
  end

  def view_admin_tabs?
    user.person.hbx_staff_role.permission.modify_admin_tabs
  end

end