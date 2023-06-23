class PersonPolicy < ApplicationPolicy
  def updateable?
    return true unless role = user.person.hbx_staff_role
    role.permission.modify_family
  end

  def can_read_inbox?
    return true if user.person.hbx_staff_role
    true if user.person.broker_role || record.broker_role
  end
end
