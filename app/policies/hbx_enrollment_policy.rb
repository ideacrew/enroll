# frozen_string_literal: true

class HbxEnrollmentPolicy < ApplicationPolicy

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

  def plan_selection_callback?
    create?
  end

  def set_elected_aptc?
    can_create_ivl_enrollment?
  end

  def plans?
    create?
  end

  private
  # Returns the family associated with the current enrollment.
  #
  # @return [Family] The family associated with the current enrollment.
  def enrollment_family
    @enrollment_family ||= record.family
  end

  def can_create_ivl_enrollment?
    return true if individual_market_primary_family_member?(enrollment_family)
    return true if individual_market_admin?
    return true if active_associated_individual_market_family_broker?(enrollment_family)

    false
  end

  def can_create_resident_role_enrollment?
    return true if coverall_market_primary_family_member?(enrollment_family)
    return true if coverall_market_admin?
    return true if active_associated_coverall_market_family_broker?(enrollment_family)

    false
  end

  def can_create_shop_enrollment?
    return true if shop_market_primary_family_member?(enrollment_family)
    return true if shop_market_admin?
    return true if active_associated_shop_market_family_broker?(enrollment_family)
    return true if active_associated_shop_market_general_agency?(enrollment_family)

    false
  end

  def can_create_fehb_enrollment?
    return true if fehb_market_primary_family_member?(enrollment_family)
    return true if fehb_market_admin?
    return true if active_associated_fehb_market_family_broker?(enrollment_family)
    return true if active_associated_fehb_market_general_agency?(enrollment_family)

    false
  end

  def create?
    binding.pry
    case record.kind
    when HbxEnrollment::INDIVIDUAL_KIND
      can_create_ivl_enrollment?
    when HbxEnrollment::COVERALL_KIND
      can_create_resident_role_enrollment?
    when *HbxEnrollment::GROUP_KINDS
      can_create_shop_enrollment? || can_create_fehb_enrollment?
    else
      false
    end
  end
end