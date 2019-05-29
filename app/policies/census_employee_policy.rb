class CensusEmployeePolicy < ApplicationPolicy
  #TODOJF JULY 1 review this
  def update?
    if @user.has_hbx_staff_role?
      true
    else
      can_change = if (@user.has_employer_staff_role? && !@user.has_broker_role?)
        @user.person.employer_staff_roles.map(&:employer_profile_id).map(&:to_s).include? @record.employer_profile_id.try(:to_s) rescue false
      elsif @user.has_role? :broker
        @record.employer_profile.try(:active_broker) == @user.person
      elsif @user.has_general_agency_staff_role?
        emp_ids = EmployerProfile.find_by_general_agency_profile(@user.person.general_agency_staff_roles.first.general_agency_profile).map(&:id)
        emp_ids.include? ( @record.employer_profile.id)
      else
        false
      end
      can_change || (!@record.dob_changed? && !@record.ssn_changed?)
    end
  end

  def show?
    if @user.has_hbx_staff_role?
      true
    else
      binding.pry
      can_change = if (@user.has_employer_staff_role? && !@user.has_broker_role?)
        @user.person.employer_staff_roles.map(&:employer_profile_id).map(&:to_s).include? @record.employer_profile_id.try(:to_s) rescue false
      elsif @user.has_broker_role?
        @record.employer_profile.try(:active_broker) == @user.person
      elsif @user.has_broker_agency_staff_role?
        profile_ids = @user.person.broker_agency_staff_roles.map(&:broker_agency_profile_id)
        profile_ids.include? (@record.employer_profile.broker_agency_profile.id)
      elsif @user.has_general_agency_staff_role?
        emp_ids = EmployerProfile.find_by_general_agency_profile(@user.person.general_agency_staff_roles.first.general_agency_profile).map(&:id)
        emp_ids.include? ( @record.employer_profile.id)
      else
        false
      end
      can_change
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
