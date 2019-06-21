class QlePolicy < ApplicationPolicy
  def view_manage_qle?
    user.has_hbx_staff_role?
  end
end
