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

  # Checking if consumer identity has been verified or if user has hbx_staff_role.
  # If either are true, then the user has access beyond the RIDP page.
  def ridp_verified?
    user_person = @user&.person
    # NOTE: brokers and consumers both require consumer identity to be verified beyond ridp page
    # TODO:
    # 1. Need to confirm how this behaves when user is logged in as broker
    #    If @user returns the broker, then we need to find a way to check the consumer's identity.
    #    Presumably, consumer role id or consumer's person id is available somewhere in the request.
    #    If @user is returning the consumer somehow, then the condition below is sufficient.
    # 2. Confirm how this behaves when user is logged in as hbx admin

    # Leaving commented code below, but it may need to be removed when above is confirmed
    # broker_staff_roles = user_person.active_broker_staff_roles
    # broker_role = user_person.broker_role
    # if broker_role.present? || broker_staff_roles.any?
    #   can_broker_modify_consumer?(broker_role, broker_staff_roles)
    # end
    user_person&.hbx_staff_role&.permission&.modify_family || user_person&.consumer_role&.identity_verified?
  end

  def can_broker_modify_consumer?(broker, broker_staff)
    ivl_broker_account = @record&.person.primary_family.active_broker_agency_account
    return false unless ivl_broker_account.present?
    return true if broker.present? && ivl_broker_account.benefit_sponsors_broker_agency_profile_id == broker.benefit_sponsors_broker_agency_profile_id
    staff_account = broker_staff.detect{|staff_role| staff_role.benefit_sponsors_broker_agency_profile_id == ivl_broker_account.benefit_sponsors_broker_agency_profile_id} if broker_staff.present?
    return false unless staff_account
    return true if ivl_broker_account.benefit_sponsors_broker_agency_profile_id == staff_account.benefit_sponsors_broker_agency_profile_id
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
