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

  # Checks if the logged in person of the current_user is the same as the primary applicant of the application,
  # if the logged in current_user is a broker and is the active broker of the family of the application.
  #
  # @return [Boolean] Returns true if any of the conditions are met, false otherwise.
  def modify_and_view_as_self_or_broker?
    user.person.id == record.person.id || associated_active_broker?
  end

  # Checks if the user is hbx staff member and is eligible to modify a family.
  # A user is considered eligible if they have the hbx staff role and permission to modify a family.
  #
  # @return [Boolean, nil] Returns true if the user is an eligible hbx staff member, false if they are not, or nil if the user or their permissions are not defined.
  def hbx_staff_modify_family?
    user.person.hbx_staff_role&.permission&.modify_family
  end

  # Checks if the consumer's identity has been verified.
  #
  # @return [Boolean] Returns true if the consumer's identity has been verified, false otherwise.
  def ridp_verified?
    record.identity_verified?
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
  def help_paying_coverage?
    # NOTE: brokers and consumers both require consumer identity to be verified beyond ridp page
    # the second condition covers both cases
    @user&.person&.hbx_staff_role&.permission&.modify_family || ridp_verified?
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

  private

  # Checks if the user is associated with an active broker.
  # A user is considered associated with an active broker if the broker is not blank, is active, and matches the broker associated with the primary family of the person associated with the record.
  #
  # @return [Boolean] Returns true if the user is associated with an active broker, false otherwise.
  def associated_active_broker?
    broker = user.person.broker_role
    return false if broker.blank? || !broker.active?

    baa = record.person.primary_family.active_broker_agency_account
    return false if baa.blank?

    baa.benefit_sponsors_broker_agency_profile_id == broker.benefit_sponsors_broker_agency_profile_id &&
      baa.writing_agent_id == broker.id
  end
end
