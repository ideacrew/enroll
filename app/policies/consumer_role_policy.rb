class ConsumerRolePolicy < ApplicationPolicy
  def initialize(user, record)
    super
    @family = record.person.primary_family if record.is_a?(ConsumerRole)
  end

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

  # Determines if the current user has permission to upload verification documents.
  # The user can upload verification documents if they are a primary family member in the individual market,
  # an individual market admin, an active associated individual market family broker staff,
  # or an active associated individual market family broker.
  #
  # @return [Boolean] Returns true if the user has permission to upload verification documents, false otherwise.
  def verification_document_upload?
    return true if individual_market_primary_family_member?
    return true if individual_market_admin?
    return true if active_associated_individual_market_family_broker_staff?
    return true if active_associated_individual_market_family_broker?

    false
  end

  # Determines if the current user has permission to download verification document.
  # The user can download the document if they are a primary family member,
  # an active associated broker, or an admin in the individual market,
  #
  # @return [Boolean] Returns true if the user has permission to download the document, false otherwise.
  def verification_document_download?
    return true if individual_market_primary_family_member?
    return true if individual_market_admin?
    return true if active_associated_individual_market_family_broker_staff?
    return true if active_associated_individual_market_family_broker?

    false
  end

  # Determines if the current user has permission to upload ridp document.
  # The user can download the document if they are a primary family member,
  # an active associated broker, or an admin in the individual market,
  #
  # @return [Boolean] Returns true if the user has permission to download the document, false otherwise.
  def ridp_document_upload?
    return true if individual_market_non_ridp_primary_family_member?
    return true if individual_market_admin?
    return true if active_associated_individual_market_family_broker_staff?
    return true if active_associated_individual_market_family_broker?

    false
  end


  # Determines if the current user has permission to download ridp document.
  # The user can download the document if they are a primary family member,
  # an active associated broker, or an admin in the individual market,
  #
  # @return [Boolean] Returns true if the user has permission to download the document, false otherwise.
  def ridp_document_download?
    return true if individual_market_non_ridp_primary_family_member?
    return true if individual_market_admin?
    return true if active_associated_individual_market_family_broker_staff?
    return true if active_associated_individual_market_family_broker?

    false
  end

  # Determines if the current user has permission to delete ridp document.
  # The user can delete the document if they are a primary family member,
  # an active associated broker, or an admin in the individual market,
  #
  # @return [Boolean] Returns true if the user has permission to delete the document, false otherwise.
  def ridp_document_delete?
    return true if individual_market_non_ridp_primary_family_member?
    return true if individual_market_admin?
    return true if active_associated_individual_market_family_broker_staff?
    return true if active_associated_individual_market_family_broker?

    false
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
    # NOTE: brokers and consumers both require consumer identity to be verified beyond ridp page
    # the second condition covers both cases
    @user&.person&.hbx_staff_role&.permission&.modify_family || RemoteIdentityProofingStatus.is_complete_for_consumer_role?(record)
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
