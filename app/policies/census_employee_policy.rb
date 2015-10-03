class CensusEmployeePolicy < ApplicationPolicy
  def update?
    if @user.has_role? :employer_staff or
       @user.has_role? :broker or
       @user.has_role? :hbx_staff
      true
    else
      !@record.dob_changed? and !@record.ssn_changed?
    end
  end

  def delink?
    if @user.has_role? :hbx_staff or
       @user.has_role? :broker_agency_staff or
       @user.has_role? :broker
      @record.employee_role_linked?
    else
      false
    end
  end
end
