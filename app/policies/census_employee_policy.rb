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
    return true if (@user.has_role? :hbx_staff || @user.has_hbx_staff_role?)
    if @user.has_role? :broker || @user.has_broker_role?
      return true if @record.employer_profile.try(:active_broker) == @user.person
    end
    if @user.has_role?(:employer_staff) || @user.has_employer_staff_role?
      return true if @user.person.employer_staff_roles.map(&:employer_profile_id).map(&:to_s).include? @record.employer_profile_id.to_s     
    end  
    if @user.has_role?(:general_agency_staff) || @user.has_general_agency_staff_role?
      ga_id = @user.person.general_agency_staff_roles.last.general_agency_profile.id
      employer_id = @record.employer_profile.id
      return false if ga_id.nil? || employer_id.nil?
      plan_design_organizations = SponsoredBenefits::Organizations::PlanDesignOrganization.find_by_sponsor(employer_id)
      plan_design_organizations.each do |a|
          if !a.general_agency_profile.nil?
            return true if a.general_agency_profile.id == ga_id
          end
      end
      return false
    end
    return false
  end

  def delink?
    if @user.has_role? :hbx_staff or @user.has_role? :broker_agency_staff or @user.has_role? :broker
      @record.is_linked?
    else
      false
    end
  end
end