# frozen_string_literal: true

# The PersonPolicy class defines the rules for which actions can be performed on a Person object.
# Each public method corresponds to a potential action that can be performed.
# The private methods are helper methods used to determine whether a user has the necessary permissions to perform an action.
class PersonPolicy < ApplicationPolicy
  def initialize(user, record)
    super
    @family = (record.primary_family || record.families.first) if record.is_a?(Person)
  end

  # Is the given entity allowed to complete RIDP on behalf of a given
  # individual?
  def complete_ridp?
    @family = record.primary_family
    consumer_role = record.consumer_role
    return false unless consumer_role
    return true if active_associated_individual_market_family_broker_staff?
    return true if active_associated_individual_market_family_broker?
    return true if individual_market_admin?
    (consumer_role == individual_market_role)
  end

  def can_show?
    allowed_to_modify?
  end

  def can_update?
    allowed_to_modify?
  end

  def can_download_document?
    allowed_to_download?
  end

  def can_delete_document?
    allowed_to_download?
  end

  def updateable?
    return true unless role = user.person.hbx_staff_role
    role.permission.modify_family
  end

  def can_read_inbox?
    return true if user.person.hbx_staff_role
    true if user.person.broker_role || record.broker_role
  end

  def can_access_identity_verifications?
    return true if user.person.hbx_staff_role
    return true if user.person.id == record.id
    false
  end

  # This method checks if the current user have an HBX staff role, has the permission to modify the family.
  #
  # Example:
  #   can_hbx_staff_modify? # => true/false
  def can_hbx_staff_modify?
    has_hbx_staff_role? && role&.permission&.modify_family
  end

  # This method checks if the current user have a broker role, has the permission to modify either the individual account or the shop account.
  #
  # Example:
  #   can_broker_modify? # => true/false
  def can_broker_modify?
    has_broker_role? && (matches_individual_broker_account? || matches_shop_broker_account?)
  end

  # rubocop:disable Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity
  def can_download_sbc_documents?
    return true if individual_market_primary_family_member?
    return true if individual_market_admin?
    return true if active_associated_individual_market_family_broker_staff?
    return true if active_associated_individual_market_family_broker?

    return true if shop_market_primary_family_member?
    return true if shop_market_admin?
    return true if active_associated_shop_market_family_broker?
    return true if active_associated_shop_market_general_agency?

    return true if fehb_market_primary_family_member?
    return true if fehb_market_admin?
    return true if active_associated_fehb_market_family_broker?
    return true if active_associated_fehb_market_general_agency?

    return true if coverall_market_primary_family_member?
    return true if coverall_market_admin?
    return true if active_associated_coverall_market_family_broker?

    false
  end
  # rubocop:enable Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity

  private

  def allowed_to_modify?
    allowed_to_access?
  end

  def allowed_to_download?
    allowed_to_access?
  end

  # Determines if the current user has permission to upload ridp document.
  # The user can download the document if they are a primary family member,
  # an active associated broker, or an admin in the individual market,
  #
  # @return [Boolean] Returns true if the user has permission to download the document, false otherwise.
  def allowed_to_access?
    return true if individual_market_primary_family_member?
    return true if shop_market_primary_family_member?
    return true if individual_market_admin?
    return true if shop_market_admin?
    return true if active_associated_individual_market_family_broker_staff?
    return true if active_associated_individual_market_ridp_verified_family_broker?
    return true if active_associated_individual_market_family_broker?

    false
  end
end
