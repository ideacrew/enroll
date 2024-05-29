# frozen_string_literal: true

# used to simulate inheriting from the main app's ApplicationPolicy in the GHAs
class ApplicationPolicy # rubocop:disable Metrics/ClassLength
  attr_reader :user, :record, :family

  def initialize(user, record)
    @user = user
    @record = record
  end

  # Returns the user who is the account holder.
  #
  # @return [User] The user who is the account holder.
  def account_holder
    user
  end

  # Returns the person who is the account holder.
  # The method uses memoization to store the result of the first call to it and then return that result on subsequent calls,
  # instead of calling `account_holder.person` each time.
  #
  # @return [Person] The person who is the account holder.
  def account_holder_person
    return @account_holder_person if defined? @account_holder_person

    @account_holder_person = account_holder&.person
  end

  # Returns the individual market role of the account holder person.
  # The method uses memoization to store the result of the first call to it and then return that result on subsequent calls,
  # instead of calling `account_holder_person.consumer_role` each time.
  #
  # @return [ConsumerRole, nil] The individual market role of the account holder person,
  # or nil if the account holder person is not defined.
  def individual_market_role
    return @individual_market_role if defined? @individual_market_role

    @individual_market_role = account_holder_person&.consumer_role
  end

  # Returns the coverall market role of the account holder person.
  # The method uses memoization to store the result of the first call to it and then return that result on subsequent calls,
  # instead of calling `account_holder_person.resident_role` each time.
  #
  # @return [ResidentRole, nil] The coverall market role of the account holder person,
  # or nil if the account holder person is not defined.
  def coverall_market_role
    return @coverall_market_role if defined? @coverall_market_role

    @coverall_market_role = account_holder_person&.resident_role
  end

  # Returns the family of the account holder.
  # If the @account_holder_family is defined and is set to nil, then the method will return nil.
  # Otherwise, it will fetch the value of `account_holder_person&.primary_family` and returns the @account_holder_family.
  # If we use `@account_holder_family ||= account_holder_person&.primary_family` when the value is nil, the code will call `account_holder_person.primary_family` which is not necessary.
  # Reference: https://www.justinweiss.com/articles/4-simple-memoization-patterns-in-ruby-and-one-gem/
  #
  # @return [Family, nil] The family of the account holder or nil if not defined or not present.
  def account_holder_family
    return @account_holder_family if defined? @account_holder_family

    @account_holder_family = account_holder_person&.primary_family
  end

  # @!group ACA Individual Market related methods

  # Determines if the current user is a primary family member in the individual market.
  # The user is considered a primary family member if they have verified their identity in the individual market (RIDP verified) and their account holder's family is the same as the current family.
  #
  # @return [Boolean] Returns true if the user is a primary family member in the individual market, false otherwise.
  def individual_market_primary_family_member?
    individual_market_ridp_verified? && (account_holder_family == family)
  end

  # Determines if the current user is a primary family member in the individual market who has not verified their identity (RIDP).
  # The user is considered a primary family member if they have an individual market role and their account holder's family is the same as the current family.
  #
  # @return [Boolean] Returns true if the user is a primary family member in the individual market who has not verified their identity, false otherwise.
  def individual_market_non_ridp_primary_family_member?
    individual_market_role && (account_holder_family == family)
  end

  # Determines if the current user has verified their identity in the individual market (RIDP).
  #
  # @return [Boolean] Returns true if the user has verified their identity in the individual market, false otherwise.
  def individual_market_ridp_verified?
    # Note here, for now, we need to support the identity verification also present on the user.
    individual_market_role&.identity_verified? || user.identity_verified?
  end

  # Determines if the primary person of the family has verified their identity (RIDP).
  #
  # @return [Boolean] Returns true if the primary person of the family has verified their identity, false otherwise.
  def primary_family_member_ridp_verified?
    primary = family&.primary_person
    return false if primary.blank?

    consumer_role = primary.consumer_role
    return false if consumer_role.blank?

    consumer_role.identity_verified?
  end

  # Checks if the current user is a primary family member who has verified their identity and is an active associated individual market family broker staff.
  #
  # @return [Boolean] Returns true if the primary family member has verified their
  # identity and the user is an active associated individual market family broker staff, false otherwise.
  def active_associated_individual_market_ridp_verified_family_broker_staff?
    primary_family_member_ridp_verified? && active_associated_individual_market_family_broker_staff?
  end

  # Checks if the current user is an active associated individual market family broker staff.
  # It checks if the user has any active broker agency staff roles and if the user's family has an active broker agency account.
  # If both conditions are met, it checks if any of the user's broker agency staff roles
  # are associated with the broker agency profile of the family's active broker agency account.
  #
  # @return [Boolean] Returns true if the user is an active associated individual market family broker staff, false otherwise.
  def active_associated_individual_market_family_broker_staff?
    broker_staffs = account_holder_person&.broker_agency_staff_roles&.active
    return false if broker_staffs.blank?

    broker_agency_account = family.active_broker_agency_account
    return false if broker_agency_account.blank?

    broker_agency = broker_agency_account.broker_agency_profile

    broker_staffs.any? do |staff|
      staff.benefit_sponsors_broker_agency_profile_id == broker_agency.id
    end
  end

  # Determines if the current user is an active associated broker in the individual market.
  # The user is considered an active associated broker if they are an active associated broker for the family in the individual market.
  # The primary family member must be verified for their identity.
  # The broker is allowed to access only if the broker is active and associated to the family if the primary person of the family is RIDP verified.
  #
  # @return [Boolean] Returns true if the user is an active associated broker in the individual market who has verified their identity, false otherwise.
  def active_associated_individual_market_ridp_verified_family_broker?
    primary_family_member_ridp_verified? && active_associated_individual_market_family_broker?
  end

  # Determines if the current user is an active associated broker in the individual market.
  # The user is considered an active associated broker if they have a broker role that is active and in the individual market,
  # and their broker agency account is active and associated with the same broker agency profile and writing agent as their broker role.
  #
  # @return [Boolean] Returns true if the user is an active associated broker in the individual market, false otherwise.
  def active_associated_individual_market_family_broker?
    broker = account_holder_person&.broker_role
    return false if broker.blank? || !broker.active? || !broker.individual_market?

    broker_agency_account = family.active_broker_agency_account
    return false if broker_agency_account.blank?

    broker_agency_account.benefit_sponsors_broker_agency_profile_id == broker.benefit_sponsors_broker_agency_profile_id &&
      broker_agency_account.writing_agent_id == broker.id
  end

  # Determines if the current user is an admin in the individual market.
  # The user is considered an admin if they have an HBX staff role that has permission to modify the family.
  #
  # @return [Boolean] Returns true if the user is an admin in the individual market, false otherwise.
  def individual_market_admin?
    return false if hbx_role.blank?

    permission = hbx_role.permission
    return false if permission.blank?

    permission.modify_family
  end

  # @!endgroup

  # @!group Non-ACA Coverall Market related methods

  # Checks if the account holder is a primary family member in the coverall market for the given family.
  # A user is considered a primary family member in the coverall market if they have a coverall market role and they are the primary person of the given family.
  #
  # @param family [Family] The family to check.
  # @return [Boolean] Returns true if the account holder is a primary family member in the coverall market for the given family, false otherwise.
  def coverall_market_primary_family_member?
    coverall_market_role && account_holder_person == family.primary_person
  end

  # Checks if the account holder is an active broker associated with the given family in the coverall market.
  # A user is considered an active broker associated with the family in the coverall market if they have an active broker role,
  # they are associated with the coverall market, and they are the writing agent for the family's active broker agency account.
  # TODO: We need to check if Primary Person's RIDP needs to be verified for Associated Active Certified Brokers to access Coverall Market
  #
  # @param family [Family] The family to check.
  # @return [Boolean] Returns true if the account holder is an active broker associated with the given family in the coverall market, false otherwise.
  def active_associated_coverall_market_family_broker?
    return false unless coverall_market_role

    broker = account_holder_person&.broker_role
    return false if broker.blank? || !broker.active? || !broker.individual_market?

    broker_agency_account = family.active_broker_agency_account
    return false if broker_agency_account.blank?

    broker_agency_account.benefit_sponsors_broker_agency_profile_id == broker.benefit_sponsors_broker_agency_profile_id &&
      broker_agency_account.writing_agent_id == broker.id
  end

  # Checks if the account holder is an admin in the coverall market.
  # A user is considered an admin in the coverall market if they have an hbx staff role and they have the permission to modify a family.
  # TODO: We need to check if Primary Person's RIDP needs to be verified for Hbx Staff Admins
  #
  # @return [Boolean] Returns true if the account holder is an admin in the coverall market, false otherwise.
  def coverall_market_admin?
    individual_market_admin?
  end

  # @!endgroup

  # @!group ACA Shop Market related methods

  # Checks if the account holder is a primary family member in the ACA Shop market for the given family.
  # A user is considered a primary family member in the ACA Shop market if they have an employee role and they are the primary person of the given family.
  #
  # @param family [Family] The family to check.
  # @return [Boolean] Returns true if the account holder is a primary family member in the ACA Shop market for the given family, false otherwise.
  def shop_market_primary_family_member?
    primary_person = family&.primary_person
    return false unless primary_person

    primary_person.employee_roles.present? && account_holder_person == primary_person
  end

  # Checks if the account holder is an admin in the shop market.
  # A user is considered an admin in the shop market if they have an hbx staff role and they have the permission to modify a family.
  # TODO: We need to check if Primary Person's RIDP needs to be verified for Hbx Staff Admins
  #
  # @return [Boolean] Returns true if the account holder is an admin in the shop market, false otherwise.
  def shop_market_admin?
    # hbx_role = account_holder_person.hbx_staff_role
    # return false if hbx_role.blank?

    # permission = hbx_role.permission
    # return false if permission.blank?

    # permission.modify_employer
    individual_market_admin?
  end

  def active_associated_shop_market_family_broker? # rubocop:disable Metrics/CyclomaticComplexity
    broker = account_holder_person&.broker_role
    broker_staff_roles = account_holder_person&.broker_agency_staff_roles&.active

    return false if broker.blank? && broker_staff_roles.blank?
    return false if broker.present? && (!broker.active? || !broker.shop_market?)
    return true if broker.present? && shop_market_family_broker_agency_ids.include?(broker.benefit_sponsors_broker_agency_profile_id)
    return true if broker_staff_roles.present? && (broker_staff_roles.pluck(:benefit_sponsors_broker_agency_profile_id) & shop_market_family_broker_agency_ids).present?
    false
  end

  def active_associated_shop_market_general_agency?
    account_holder_ga_roles = account_holder_person&.active_general_agency_staff_roles
    return false if account_holder_ga_roles.blank?
    return false if broker_profile_ids.blank?

    ::SponsoredBenefits::Organizations::PlanDesignOrganization.where(
      :owner_profile_id.in => broker_profile_ids,
      :general_agency_accounts => {
        :"$elemMatch" => {
          aasm_state: :active,
          :benefit_sponsrship_general_agency_profile_id.in => account_holder_ga_roles.map(&:benefit_sponsors_general_agency_profile_id)
        }
      }
    ).present?
  end

  # @endgrop

  # @!group Non-ACA Fehb Market related methods

  # Checks if the account holder is a primary family member in the Non-ACA Fehb market for the given family.
  # A user is considered a primary family member in the Non-ACA Fehb market if they are a primary family member in the ACA Shop market for the given family.
  #
  # @param family [Family] The family to check.
  # @return [Boolean] Returns true if the account holder is a primary family member in the Non-ACA Fehb market for the given family, false otherwise.
  def fehb_market_primary_family_member?
    shop_market_primary_family_member?
  end

  def fehb_market_admin?
    shop_market_admin?
  end

  def active_associated_fehb_market_family_broker?
    false
  end

  def active_associated_fehb_market_general_agency?
    false
  end

  # @!endgroup

  # @!group Hbx Staff Role permissions

  def staff_view_admin_tabs?
    permission&.view_admin_tabs
  end

  def staff_modify_employer?
    permission&.modify_employer
  end

  def staff_modify_admin_tabs?
    permission&.modify_admin_tabs
  end

  def staff_view_the_configuration_tab?
    permission&.view_the_configuration_tab
  end

  def staff_can_submit_time_travel_request?
    permission&.can_submit_time_travel_request
  end

  def staff_can_edit_aptc?
    permission&.can_edit_aptc
  end

  def staff_send_broker_agency_message?
    permission&.send_broker_agency_message
  end

  def staff_approve_broker?
    permission&.approve_broker
  end

  def staff_approve_ga?
    permission&.approve_ga
  end

  def staff_can_extend_open_enrollment?
    permission&.can_extend_open_enrollment
  end

  def staff_can_modify_plan_year?
    permission&.can_modify_plan_year
  end

  def staff_can_create_benefit_application?
    permission&.can_create_benefit_application
  end

  def staff_can_change_fein?
    permission&.can_change_fein
  end

  def staff_can_force_publish?
    permission&.can_force_publish
  end

  def staff_can_access_age_off_excluded?
    permission&.can_access_age_off_excluded
  end

  def staff_can_send_secure_message?
    permission&.can_send_secure_message
  end

  def staff_can_add_sep?
    permission&.can_add_sep
  end

  def staff_can_view_sep_history?
    permission&.can_view_sep_history
  end

  def staff_can_cancel_enrollment?
    permission&.can_cancel_enrollment
  end

  def staff_can_terminate_enrollment?
    permission&.can_terminate_enrollment
  end

  def staff_can_reinstate_enrollment?
    permission&.can_reinstate_enrollment
  end

  def staff_can_drop_enrollment_members?
    permission&.can_drop_enrollment_members
  end

  def staff_change_enrollment_end_date?
    permission&.change_enrollment_end_date
  end

  def staff_can_access_identity_verification_sub_tab?
    permission&.can_access_identity_verification_sub_tab
  end

  def staff_can_access_outstanding_verification_sub_tab?
    permission&.can_access_outstanding_verification_sub_tab
  end

  def staff_can_access_accept_reject_identity_documents?
    permission&.can_access_accept_reject_identity_documents
  end

  def staff_can_access_accept_reject_paper_application_documents?
    permission&.can_access_accept_reject_paper_application_documents
  end

  def staff_can_delete_identity_application_documents?
    permission&.can_delete_identity_application_documents
  end

  def staff_can_access_user_account_tab?
    permission&.can_access_user_account_tab
  end

  def staff_can_access_pay_now?
    permission&.can_access_pay_now
  end

  def staff_can_add_pdc?
    permission&.can_add_pdc
  end

  def staff_can_call_hub?
    permission&.can_call_hub
  end

  def staff_can_edit_osse_eligibility?
    permission&.can_edit_osse_eligibility
  end

  def staff_can_view_audit_log?
    permission&.can_view_audit_log
  end

  def staff_can_update_ssn?
    permission&.can_update_ssn
  end

  def staff_can_lock_unlock?
    permission&.can_lock_unlock
  end

  def staff_can_reset_password?
    permission&.can_reset_password
  end

  def staff_can_change_username_and_email?
    permission&.can_change_username_and_email
  end

  def staff_view_login_history?
    permission&.view_login_history
  end

  def permission
    return @permission if defined? @permission

    @permission = hbx_role&.permission
  end

  def hbx_role
    return @hbx_role if defined? @hbx_role

    @hbx_role = account_holder_person&.hbx_staff_role
  end

  # @!endgroup

  def index?
    read_all?
  end

  def show?
    scope.where(:id => record.id).exists?
  end

  def create?
    false
  end

  def new?
    create?
  end

  def update?
    update_all?
  end

  def edit?
    update?
  end

  def destroy?
    false
  end

  def scope
    Pundit.policy_scope!(user, record.class)
  end

  def read_all? # rubocop:disable Metrics/CyclomaticComplexity
    @user.has_role? :employer_staff or
      @user.has_role? :employee or
      @user.has_role? :broker or
      @user.has_role? :broker_agency_staff or
      @user.has_role? :consumer or
      @user.has_role? :resident or
      @user.has_role? :hbx_staff or
      @user.has_role? :system_service or
      @user.has_role? :web_service or
      @user.has_role? :assister or
      @user.has_role? :csr
  end

  def update_all?
    @user.has_role? :broker_agency_staff or
      @user.has_role? :assister or
      @user.has_role? :csr
  end

  # used to simulate inheriting from the main app's ApplicationPolicy in the GHAs
  class Scope
    attr_reader :user, :scope

    def initialize(user, scope)
      @user = user
      @scope = scope
    end

    def resolve
      scope
    end
  end

  private

  def broker_profile_ids
    return @broker_profile_ids if defined? @broker_profile_ids

    @broker_profile_ids = ([individual_market_family_broker_agency_id] + shop_market_family_broker_agency_ids).compact
  end

  def individual_market_family_broker_agency_id
    return @individual_market_family_broker_agency_id if defined? @individual_market_family_broker_agency_id

    @individual_market_family_broker_agency_id = family.current_broker_agency&.benefit_sponsors_broker_agency_profile_id
  end

  def shop_market_family_broker_agency_ids
    return @shop_market_family_broker_agency_ids if defined? @shop_market_family_broker_agency_ids

    @shop_market_family_broker_agency_ids = family.primary_person.active_employee_roles.map do |er|
      er.employer_profile&.active_broker_agency_account&.benefit_sponsors_broker_agency_profile_id
    end.compact
  end
end
