# frozen_string_literal: true

class HbxEnrollmentPolicy < ApplicationPolicy
  # Initializes the HbxEnrollmentPolicy with a user and a record.
  # It also sets the @family instance variable to the family of the record.
  #
  # @param user [User] the user to initialize the policy with.
  # @param record [HbxEnrollment] the record to initialize the policy with.
  def initialize(user, record)
    super
    @family = record.family
  end

  # Determines if the current user has permission to checkout.
  # The user can checkout if they have permission to create a family.
  #
  # @return [Boolean] Returns true if the user has permission to checkout, false otherwise.
  def checkout?
    create?
  end

  # Determines if the current user has permission to view the receipt.
  # The user can view the receipt if they have permission to create a family.
  #
  # @return [Boolean] Returns true if the user has permission to view the receipt, false otherwise.
  def receipt?
    create?
  end

  # Determines if the current user has permission to view the thank you page.
  # The user can view the thank you page if they have permission to create a family.
  #
  # @return [Boolean] Returns true if the user has permission to view the thank you page, false otherwise.
  def thankyou?
    create?
  end

  # Determines if the current user has permission to waive.
  # The user can waive if they have permission to create a family.
  #
  # @return [Boolean] Returns true if the user has permission to waive, false otherwise.
  def waive?
    create?
  end

  # Determines if the current user has permission to print a waiver.
  # The user can print a waiver if they have permission to create a family.
  #
  # @return [Boolean] Returns true if the user has permission to print a waiver, false otherwise.
  def print_waiver?
    create?
  end

  def terminate_confirm?
    terminate?
  end

  # Determines if the current user has permission to edit a plan.
  # The user can edit a plan if they have permission to create a family.
  #
  # @return [Boolean] Returns true if the user has permission to edit a plan, false otherwise.
  def edit_plan?
    create?
  end

  # Determines if the current user has permission to terminate or cancel.
  # The user can terminate or cancel if they have permission to create a family.
  #
  # @return [Boolean] Returns true if the user has permission to terminate or cancel, false otherwise.
  def term_or_cancel?
    create?
  end

  def terminate?
    return true if shop_market_primary_family_member?
    return true if shop_market_admin?
    return true if active_associated_shop_market_family_broker?
    return true if active_associated_shop_market_general_agency?

    return true if fehb_market_primary_family_member?
    return true if fehb_market_admin?
    return true if active_associated_fehb_market_family_broker?
    return true if active_associated_fehb_market_general_agency?

    false
  end

  # Determines if the current user has permission to view.
  # The user can view if they have permission to create a family.
  #
  # @return [Boolean] Returns true if the user has permission to view, false otherwise.
  def show?
    create?
  end

  # Determines if the current user has permission to perform a plan selection callback.
  # The user can perform a plan selection callback if they have permission to create a family.
  #
  # @return [Boolean] Returns true if the user has permission to perform a plan selection callback, false otherwise.
  def plan_selection_callback?
    create?
  end

  # Determines if the current user has permission to edit APTC (Advanced Premium Tax Credit).
  # The user can edit APTC if they have permission to set elected APTC.
  #
  # @return [Boolean] Returns true if the user has permission to edit APTC, false otherwise.
  def edit_aptc?
    set_elected_aptc?
  end

  # Determines if the current user has permission to set elected APTC (Advanced Premium Tax Credit).
  # The user can set elected APTC if they are a primary family member in the individual market,
  # an individual market admin, an active associated individual market RIDP verified family broker staff,
  # or an active associated individual market RIDP verified family broker.
  #
  # @return [Boolean] Returns true if the user has permission to set elected APTC, false otherwise.
  def set_elected_aptc?
    return true if individual_market_primary_family_member?
    return true if individual_market_admin?
    return true if active_associated_individual_market_ridp_verified_family_broker_staff?
    return true if active_associated_individual_market_ridp_verified_family_broker?

    false
  end

  # Determines if the current user has permission to view plans.
  # The user can view plans if they have permission to create a family.
  #
  # @return [Boolean] Returns true if the user has permission to view plans, false otherwise.
  def plans?
    create?
  end

  private

  # rubocop:disable Metrics/CyclomaticComplexity
  # Determines if the current user has permission to create a family.
  # The user can create a family if they are a primary family member in the individual market,
  # an individual market admin, an active associated individual market RIDP verified family broker staff,
  # an active associated individual market RIDP verified family broker, a primary family member in the shop market,
  # a shop market admin, an active associated shop market family broker, an active associated shop market general agency,
  # a primary family member in the FEHB market, a FEHB market admin, an active associated FEHB market family broker,
  # an active associated FEHB market general agency, a primary family member in the Coverall market, a Coverall market admin,
  # or an active associated Coverall market family broker.
  #
  # @return [Boolean] Returns true if the user has permission to create a family, false otherwise.
  def create?
    return true if individual_market_primary_family_member?
    return true if individual_market_admin?
    return true if active_associated_individual_market_ridp_verified_family_broker_staff?
    return true if active_associated_individual_market_ridp_verified_family_broker?

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
  # rubocop:enable Metrics/CyclomaticComplexity
end