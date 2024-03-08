# frozen_string_literal: true

class HbxEnrollmentPolicy < ApplicationPolicy

  def can_access_ivl_enrollment?
    can_access_individual_market_family?(record.family)
  end

  def can_access_resident_role_enrollment?
    can_access_individual_market_family_without_ridp?(record.family)
  end

  def can_access_shop_enrollment?
    can_access_shop_market_family?(record.family)
  end

  def can_access_fehb_enrollment?
    can_access_fehb_market_family?(record.family)
  end

  def can_access_enrollment?
    case record.kind
    when HbxEnrollment::INDIVIDUAL_KIND
      can_access_ivl_enrollment?
    when HbxEnrollment::COVERALL_KIND
      can_access_resident_role_enrollment?
    when *HbxEnrollment::GROUP_KINDS
      can_access_shop_enrollment? || can_access_fehb_enrollment?
    else
      false
    end
  end
end
