module AccessPolicies
  class EmployeeRole
    attr_accessor :user

    def initialize(user)
      @user = user
    end

    def authorize_employee_role(employee_role, controller)
      return true if user.has_hbx_staff_role?
      if !(user.person.employee_roles.map(&:id).map(&:to_s).include? employee_role.id.to_s)
        controller.redirect_to_check_employee_role
      else
        return true
      end
    end
  end
end
