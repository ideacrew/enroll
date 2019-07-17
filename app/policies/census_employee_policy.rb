class CensusEmployeePolicy < ApplicationPolicy
  #TODOJF JULY 1 review this
  def update?
    if @user.has_role? :hbx_staff
      true
    else
      can_change = if (@user.has_role?(:employer_staff) && !@user.has_role?(:broker))
        @user.person.employer_staff_roles.any? do |employer_staff_role|
          employer_staff_role.benefit_sponsor_employer_profile_id == @record.benefit_sponsors_employer_profile_id
        end
      elsif @user.has_role? :broker
        @record.employer_profile.try(:active_broker) == @user.person
      elsif @user.has_role?(:general_agency_staff)
        ga_account = @record.employer_profile.general_agency_accounts.select do |general_agency_account|
          @user.person.general_agency_staff_roles.where(benefit_sponsors_general_agency_profile_id: general_agency_account.benefit_sponsrship_general_agency_profile_id)
        end.first
        ga_account.present? && ga_account.active?
      else
        false
      end
      can_change || (!@record.dob_changed? && !@record.ssn_changed?)
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
