class UserPolicy < ApplicationPolicy

  def lockable?
    return false unless role = user.person && user.person.hbx_staff_role
    role.permission.can_lock_unlock
  end

  def reset_password?
    return false unless role = user.person && user.person.hbx_staff_role
    role.permission.can_reset_password
  end

end
