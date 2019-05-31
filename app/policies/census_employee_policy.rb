class CensusEmployeePolicy < ApplicationPolicy
  #TODOJF JULY 1 review this
  def update?
    if @user.has_role? :hbx_staff
      true
    else
      can_change =  if (@user.has_role?(:employer_staff) && !@user.has_role?(:broker))
                      @user.person.employer_staff_roles.map(&:employer_profile_id).map(&:to_s).include? @record.employer_profile_id.to_s
                    elsif @user.has_role? :broker
                      @record.employer_profile.try(:active_broker) == @user.person
                    elsif @user.has_role?(:general_agency_staff)
                      emp_ids = EmployerProfile.find_by_general_agency_profile(@user.person.general_agency_staff_roles.first.general_agency_profile).map(&:id)
                      emp_ids.include?(@record.employer_profile.id)
                    else
                      false
                    end
      can_change || (!@record.dob_changed? && !@record.ssn_changed?)
    end
  end

  def show?
    return true if @user.has_role? :hbx_staff
    if @user.has_role? :broker
      return true if @record.employer_profile.try(:active_broker) == @user.person
    elsif @user.has_role?(:employer_staff)
      return true if @user.person.employer_staff_roles.map(&:employer_profile_id).map(&:to_s).include? @record.employer_profile_id.to_s       
    elsif @user.has_role?(:general_agency_staff)
      linked_general_agency = @record.employer_profile.general_agency_profile
      return false if linked_general_agency.nil?
      general_agency_profile_ids = @user.person.active_general_agency_staff_roles.map{|a| a.general_agency_profile_id}
      return true if general_agency_profile_ids.include?(linked_general_agency.id)
    else
      return false
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