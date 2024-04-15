# frozen_string_literal: true

class FamilyPolicy < ApplicationPolicy
  def initialize(user, record)
    super
    @family = record
    puts "FamilyPolicy record = #{record.inspect}"
  end

  # Returns the primary person of the family record.
  #
  # @return [Person] The primary person of the family record.
  def primary_person
    record.primary_person
  end

  # Determines if the current user has permission to edit the family record.
  # The user can edit the record if they have permission to view it.
  #
  # @return [Boolean] Returns true if the user has permission to edit the record, false otherwise.
  def edit?
    show?
  end

  # Determines if the current user has permission to view the list of family records.
  # The user can view the list if they have permission to view a single record.
  #
  # @return [Boolean] Returns true if the user has permission to view the list of records, false otherwise.
  def index?
    show?
  end

  # Determines if the current user has permission to create a new family record.
  # The user can create a new record if they have permission to view a record.
  #
  # @return [Boolean] Returns true if the user has permission to create a new record, false otherwise.
  def new?
    show?
  end

  # Determines if the current user has permission to view the family record.
  # The user can view the record if they are a primary family member,
  # an active associated broker, or an admin in the individual market,
  # the ACA Shop market, the Non-ACA Fehb market, or the coverall market.
  #
  # @return [Boolean] Returns true if the user has permission to view the record, false otherwise.
  # @note This method checks for permissions across multiple markets and roles.
  def show?
    return true if individual_market_primary_family_member?
    return true if individual_market_admin?
    puts "active_associated_individual_market_family_broker_staff? #{active_associated_individual_market_family_broker_staff?}"
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

  def request_help?
    return true if individual_market_non_ridp_primary_family_member?
    show?
  end

  def hire_broker_agency?
    return true if individual_market_primary_family_member?
    return true if individual_market_non_ridp_primary_family_member?
    return true if individual_market_admin?

    return true if shop_market_primary_family_member?
    return true if shop_market_admin?

    return true if fehb_market_primary_family_member?
    return true if fehb_market_admin?

    return true if coverall_market_primary_family_member?
    return true if coverall_market_admin?

    false
  end

  def admin_show?
    return true if individual_market_admin?
    return true if shop_market_admin?
    return true if fehb_market_admin?
    return true if coverall_market_admin?

    false
  end

  def home?
    show?
  end

  def enrollment_history?
    show?
  end

  def manage_family?
    show?
  end

  def personal?
    show?
  end

  def inbox?
    show?
  end

  def verification?
    show?
  end

  def find_sep?
    show?
  end

  def record_sep?
    show?
  end

  def purchase?
    show?
  end

  def check_qle_reason?
    show?
  end

  def check_qle_date?
    show?
  end

  def sep_zip_compare?
    show?
  end

  # Determines if the user has permission to upload a paper application.
  # This feature is only applicable for the Coverall Market.
  # The user can upload a paper application if they are an admin in the coverall market.
  #
  # @return [Boolean] Returns true if the user has permission to upload a paper application, false otherwise.
  # @note This method is used in the upload_paper_application action of the PaperApplicationsController.
  def upload_paper_application?
    coverall_market_admin?
  end

  # Determines if the user has permission to download a paper application.
  # This feature is only applicable for the Coverall Market.
  # The user can download a paper application if they are an admin in the coverall market.
  #
  # @return [Boolean] Returns true if the user has permission to download a paper application, false otherwise.
  # @note This method is used in the download_paper_application action of the PaperApplicationsController.
  def download_paper_application?
    coverall_market_admin?
  end

  def upload_application?
    admin_show?
  end

  def upload_notice?
    admin_show?
  end

  def upload_notice_form?
    admin_show?
  end

  def transition_family_members?
    admin_show?
  end

  def brokers?
    show?
  end

  def delete_consumer_broker?
    return true if individual_market_primary_family_member?
    return true if individual_market_admin?

    return true if shop_market_primary_family_member?
    return true if shop_market_admin?

    return true if fehb_market_primary_family_member?
    return true if fehb_market_admin?

    return true if coverall_market_primary_family_member?
    return true if coverall_market_admin?

    false
  end

  def resident_index?
    show?
  end

  def new_resident_dependent?
    show?
  end

  def edit_resident_dependent?
    show?
  end

  def show_resident_dependent?
    show?
  end

  # Determines if the current user has permission to create a new family record.
  # TODO: Implement the logic to check if the user has permission to create a new family record.
  #
  # @return [Boolean] Returns true if the user has permission to create a new record, false otherwise.
  def create?
    show?
  end

  # Determines if the current user has permission to update the family record.
  # TODO: Implement the logic to check if the user has permission to update the family record.
  #
  # @return [Boolean] Returns true if the user has permission to update the record, false otherwise.
  def update?
    show?
  end

  # Determines if the current user has permission to destroy the family record.
  # TODO: Implement the logic to check if the user has permission to destroy the family record.
  #
  # @return [Boolean] Returns true if the user has permission to destroy the record, false otherwise.
  def destroy?
    show?
  end

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
