class CensusEmployeePolicy < ApplicationPolicy
  # TODO: JF JULY 1 review this
  def update?
    if @user.has_role? :hbx_staff
      true
    else
      can_change =  nil
      if (@user.has_role?(:employer_staff) && !@user.has_role?(:broker))
        can_change = @user.person.employer_staff_roles.map(&:employer_profile_id).map(&:to_s).include? @record.employer_profile_id.to_s
      elsif @user.has_role? :broker
        can_change = @record.employer_profile.try(:active_broker) == @user.person
      elsif @user.has_role?(:general_agency_staff)
        emp_ids = EmployerProfile.find_by_general_agency_profile(@user.person.general_agency_staff_roles.first.general_agency_profile).map(&:id)
        can_change = emp_ids.include?(@record.employer_profile.id)
      else
        can_change = false
      end
      dob_or_ssn_changed = (!@record.dob_changed? && !@record.ssn_changed?)
      can_change || dob_or_ssn_changed
    end
  end

  def delink?
    if @user.has_role? :hbx_staff or @user.has_role? :broker_agency_staff or @user.has_role? :broker
      @record.is_linked?
    else
      false
    end
  end
end
