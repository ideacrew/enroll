# frozen_string_literal: true

class FamilyPolicy < ApplicationPolicy
  def primary_person
    record.primary_person
  end

  def edit?
    show?
  end

  def index?
    show?
  end

  def new?
    show?
  end

  # March 08 2024
  def show?
    return true if individual_market_primary_family_member?(record)
    return true if active_associated_individual_market_family_broker?(record)
    return true if individual_market_admin?

    return true if shop_market_primary_family_member?(record)
    return true if fehb_market_primary_family_member?(record)

    return true if coverall_market_primary_family_member?(record)
    return true if active_associated_coverall_market_family_broker?(record)
    return true if coverall_market_admin?

    false
  end

  def create?; end

  def update?; end

  def destroy?; end

  # rubocop:disable Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity
  def legacy_show?
    user_person = @user.person
    if user_person
      primary_applicant = @record.primary_applicant
      return true if @record.primary_applicant.person_id == user_person.id
      return true if can_modify_family?(user_person)
      broker_staff_roles = user_person.active_broker_staff_roles
      broker_role = user_person.broker_role
      employee_roles = primary_applicant.person.active_employee_roles
      if broker_role.present? || broker_staff_roles.any?
        return true if can_broker_modify_family?(broker_role, broker_staff_roles)
        return false unless employee_roles.any?
        broker_agency_profile_account_ids = employee_roles.map do |er|
          er.employer_profile.active_broker_agency_account
        end.compact.map(&:benefit_sponsors_broker_agency_profile_id)
        return true if broker_role.present? && broker_agency_profile_account_ids.include?(broker_role.benefit_sponsors_broker_agency_profile_id)
        broker_staff_roles.each do |broker_staff|
          return true if broker_agency_profile_account_ids.include?(broker_staff.benefit_sponsors_broker_agency_profile_id)
        end
      end
      ga_roles = user_person.active_general_agency_staff_roles
      if ga_roles.any? && employee_roles.any?
        general_agency_profile_account_ids = employee_roles.map do |er|
          er.employer_profile.active_general_agency_account
        end.compact.map(&:benefit_sponsrship_general_agency_profile_id)
        ga_roles.each do |ga_role|
          return true if general_agency_profile_account_ids.include?(ga_role.benefit_sponsors_general_agency_profile_id)
        end
      end
    end
    false
  end
  # rubocop:enable Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity

  def can_view_entire_family_enrollment_history?
    return true if user.person.hbx_staff_role
  end

  def can_modify_family?(user_person)
    hbx_staff_role = user_person.hbx_staff_role
    return false unless hbx_staff_role
    permission = hbx_staff_role.permission
    return false unless permission
    permission.modify_family
  end

  def can_broker_modify_family?(broker, broker_staff)
    ivl_broker_account = @record.active_broker_agency_account
    return false unless ivl_broker_account.present?
    return true if broker.present? && ivl_broker_account.benefit_sponsors_broker_agency_profile_id == broker.benefit_sponsors_broker_agency_profile_id
    staff_account = broker_staff.detect{|staff_role| staff_role.benefit_sponsors_broker_agency_profile_id == ivl_broker_account.benefit_sponsors_broker_agency_profile_id} if broker_staff.present?
    return false unless staff_account
    return true if ivl_broker_account.benefit_sponsors_broker_agency_profile_id == staff_account.benefit_sponsors_broker_agency_profile_id
  end

  def role
    user&.person&.hbx_staff_role
  end

  def updateable?
    return true unless role
    role.permission.modify_family
  end

  def can_update_ssn?
    return false unless role
    role.permission.can_update_ssn
  end

  def can_edit_aptc?
    return false unless role
    role.permission.can_edit_aptc
  end

  def can_view_sep_history?
    return false unless role
    role.permission.can_view_sep_history
  end

  def can_reinstate_enrollment?
    return false unless role
    role.permission.can_reinstate_enrollment
  end

  def can_cancel_enrollment?
    return false unless role
    role.permission.can_cancel_enrollment
  end

  def can_terminate_enrollment?
    return false unless role
    role.permission.can_terminate_enrollment
  end

  def change_enrollment_end_date?
    return false unless role
    role.permission.change_enrollment_end_date
  end

  def can_drop_enrollment_members?
    return false unless role
    role.permission.can_drop_enrollment_members
  end

  def can_view_username_and_email?
    permission_role = role || user&.person&.csr_role
    return false unless permission_role
    permission_role.permission.can_view_username_and_email || user&.person&.csr_role.present?
  end

  def hbx_super_admin_visible?
    return false unless role
    role.permission.can_update_ssn
  end

  def can_transition_family_members?
    return false unless role
    role.permission.can_transition_family_members
  end

  def healthcare_for_childcare_program?
    return false if user.blank? || user.person.blank?

    user.has_hbx_staff_role? && user.person.hbx_staff_role.permission.can_edit_osse_eligibility
  end

  def can_view_audit_log?
    return false if user.blank? || user.person.blank?

    user.has_hbx_staff_role? && user.person.hbx_staff_role.permission.can_view_audit_log
  end
end
