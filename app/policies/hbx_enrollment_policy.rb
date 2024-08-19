# frozen_string_literal: true

# pundit Policies to access HbxEnrollment
class HbxEnrollmentPolicy < ApplicationPolicy
  def initialize(user, record)
    super
    @family = record.family
  end

  def checkout?
    create?
  end

  def receipt?
    create?
  end

  def thankyou?
    create?
  end

  def waive?
    create?
  end

  def print_waiver?
    create?
  end

  def terminate?
    create?
  end

  def show?
    create?
  end

  def choose_shopping_method?
    create?
  end

  def plan_selection_callback?
    create?
  end

  def summary?
    show?
  end

  def comparison?
    show?
  end

  # Determines if the current user has permission to set elected APTC (Advanced Premium Tax Credit).
  # The user can set elected APTC if they are a primary family member,
  # an admin, an active associated broker staff, or an active associated broker in the individual market.
  #
  # @return [Boolean] Returns true if the user has permission to set elected APTC, false otherwise.
  def set_elected_aptc?
    return true if individual_market_primary_family_member?
    return true if individual_market_admin?
    return true if active_associated_individual_market_family_broker_staff?
    return true if active_associated_individual_market_family_broker?

    false
  end

  def plans?
    create?
  end

  def pay_now?
    return false if record.is_shop?
    return true if individual_market_primary_family_member?
    return true if active_associated_individual_market_family_broker_staff?
    return true if active_associated_individual_market_family_broker?

    return true if coverall_market_primary_family_member?
    return true if active_associated_coverall_market_family_broker?

    return true if staff_can_access_pay_now?

    false
  end

  private

  # rubocop:disable Metrics/CyclomaticComplexity
  def create?
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
  # rubocop:enable Metrics/CyclomaticComplexity
end
