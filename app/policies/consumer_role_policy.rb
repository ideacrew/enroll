class ConsumerRolePolicy < ApplicationPolicy
  def privacy?
    if @user.has_role? :consumer or
      @user.has_role? :broker or
      @user.has_role? :assister or
      @user.has_role? :csr
      true
    elsif @user.has_role? :employer_staff or
      @user.has_role? :employee #or
      #@user.has_role? :broker_agency_staff or
      #@user.has_role? :resident or
      #@user.has_role? :hbx_staff or
      #@user.has_role? :system_service or
      #@user.has_role? :web_service
      false
    elsif @user.roles.blank?
      true
    end
  end

  def search?
    privacy?
  end

  def match?
    privacy?
  end

  def create?
    privacy?
  end

  def ridp_agreement?
    privacy?
  end

  def edit?
    person = @user.person
    if person
      if @user.has_hbx_staff_role?
        hbx_staff_role = person.hbx_staff_role
        if hbx_staff_role.permission
          return true if hbx_staff_role.permission.can_update_ssn || hbx_staff_role.permission.view_personal_info_page
        end
      end
      return true if person.id == @record.person.id
    end
    # FIXME: Shouldn't we be checking the access rights of the specific broker here?
    return true if @user.person && @user.person.has_broker_role?
    return false
  end

  # Checking presence of hbx_staff_role and if identity_validation is valid. If either are true,
  # then the user has access to continue past RIDP.
  def accessible?
    person = @user.person
    return person && (@user.has_hbx_staff_role? || person.consumer_role.identity_verified?)
    false
  end

  def update?
    edit?
  end

  def can_view_application_types?
    return @user.person.hbx_staff_role.permission.can_view_application_types if (@user.person && @user.person.hbx_staff_role)
    return false
  end

  def access_new_consumer_application_sub_tab?
    return @user.person.hbx_staff_role.permission.can_access_new_consumer_application_sub_tab if (@user.person && @user.person.hbx_staff_role)
    return false
  end

end
