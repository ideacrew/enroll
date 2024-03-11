class ApplicationPolicy
  attr_reader :user, :record

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
    @account_holder_person ||= account_holder.person
  end

  # Returns the individual market role of the account holder person.
  # The method uses memoization to store the result of the first call to it and then return that result on subsequent calls,
  # instead of calling `account_holder_person.consumer_role` each time.
  #
  # @return [ConsumerRole, nil] The individual market role of the account holder person,
  # or nil if the account holder person is not defined.
  def individual_market_role
    @individual_market_role ||= account_holder_person&.consumer_role
  end

  # Returns the coverall market role of the account holder person.
  # The method uses memoization to store the result of the first call to it and then return that result on subsequent calls,
  # instead of calling `account_holder_person.resident_role` each time.
  #
  # @return [ResidentRole, nil] The coverall market role of the account holder person,
  # or nil if the account holder person is not defined.
  def coverall_market_role
    @coverall_market_role ||= account_holder_person&.resident_role
  end

  # Returns the primary family of the account holder person.
  # The method uses memoization to store the result of the first call to it and then return that result on subsequent calls,
  # instead of calling `account_holder_person.primary_family` each time.
  #
  # @return [Family, nil] The primary family of the account holder person, or nil if the account holder person is not defined.
  def account_holder_family
    @account_holder_family ||= account_holder_person&.primary_family
  end

  # START - ACA Individual Market related methods
  #
  # Checks if the account holder is a primary family member in the individual market for the given family.
  # A user is considered a primary family member in the individual market if they have their identity verified and their primary family is the given family.
  #
  # @param family [Family] The family to check.
  # @return [Boolean] Returns true if the account holder is a primary family member in the individual market for the given family, false otherwise.
  def individual_market_primary_family_member?(family)
    individual_market_ridp_verified? && (account_holder_family == family)
  end

  # Checks if the account holder is a primary family member in the individual market for the given family, without requiring their identity to be verified.
  # A user is considered a primary family member in the individual market if they have an individual market role and their primary family is the given family.
  #
  # @param family [Family] The family to check.
  # @return [Boolean] Returns true if the account holder is a primary family member in the individual market for the given family, false otherwise.
  def individual_market_non_ridp_primary_family_member?(family)
    individual_market_role && (account_holder_family == family)
  end

  # Checks if the account holder's identity is verified in the individual market.
  # The method assumes that the individual_market_role is already defined and belongs to the account holder.
  #
  # @return [Boolean, nil] Returns true if the account holder's identity is verified in the individual market,
  # false if it's not, or nil if the account holder does not have an individual market role.
  def individual_market_ridp_verified?
    individual_market_role&.identity_verified?
  end

  # Checks if the account holder is an active broker associated with the given family in the individual market.
  # A user is considered an active broker associated with the family in the individual market if they have an active broker role,
  # they are associated with the individual market, and they are the writing agent for the family's active broker agency account.
  # TODO: We need to check if Primary Person's RIDP needs to be verified for Associated Active Certified Brokers to access Individual Market
  #
  # @param family [Family] The family to check.
  # @return [Boolean] Returns true if the account holder is an active broker associated with the given family in the individual market, false otherwise.
  def active_associated_individual_market_family_broker?(family)
    broker = account_holder_person.broker_role
    return false if broker.blank? || !broker.active? || !broker.individual_market?

    broker_agency_account = family.active_broker_agency_account
    return false if broker_agency_account.blank?

    broker_agency_account.benefit_sponsors_broker_agency_profile_id == broker.benefit_sponsors_broker_agency_profile_id &&
      broker_agency_account.writing_agent_id == broker.id
  end

  # Checks if the account holder is an admin in the individual market.
  # A user is considered an admin in the individual market if they have an hbx staff role and they have the permission to modify a family.
  # TODO: We need to check if Primary Person's RIDP needs to be verified for Hbx Staff Admins
  #
  # @return [Boolean] Returns true if the account holder is an admin in the individual market, false otherwise.
  def individual_market_admin?
    hbx_role = account_holder_person.hbx_staff_role
    return false if hbx_role.blank?

    permission = hbx_role.permission
    return false if permission.blank?

    permission.modify_family
  end

  # # TODO: We need to implement General Agency Staff access for Individual Market if needed
  # def active_associated_individual_market_family_general_agency_staff?(family)
  #   false
  # end
  #
  # END - ACA Individual Market related methods

  # START - Non-ACA Coverall Market related methods
  #
  # Checks if the account holder is a primary family member in the coverall market for the given family.
  # A user is considered a primary family member in the coverall market if they have a coverall market role and they are the primary person of the given family.
  #
  # @param family [Family] The family to check.
  # @return [Boolean] Returns true if the account holder is a primary family member in the coverall market for the given family, false otherwise.
  def coverall_market_primary_family_member?(family)
    account_holder_person == family.primary_person
  end

  # Checks if the account holder is an active broker associated with the given family in the coverall market.
  # A user is considered an active broker associated with the family in the coverall market if they have an active broker role,
  # they are associated with the coverall market, and they are the writing agent for the family's active broker agency account.
  # TODO: We need to check if Primary Person's RIDP needs to be verified for Associated Active Certified Brokers to access Coverall Market
  #
  # @param family [Family] The family to check.
  # @return [Boolean] Returns true if the account holder is an active broker associated with the given family in the coverall market, false otherwise.
  def active_associated_coverall_market_family_broker?(family)
    return false unless coverall_market_role

    broker = account_holder_person.broker_role
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
    hbx_role = account_holder_person.hbx_staff_role
    return false if hbx_role.blank?

    permission = hbx_role.permission
    return false if permission.blank?

    permission.modify_family
  end
  #
  # END - Non-ACA Coverall Market related methods

  # START - ACA Shop Market related methods
  #
  # Checks if the account holder is a primary family member in the ACA Shop market for the given family.
  # A user is considered a primary family member in the ACA Shop market if they have an employee role and they are the primary person of the given family.
  #
  # @param family [Family] The family to check.
  # @return [Boolean] Returns true if the account holder is a primary family member in the ACA Shop market for the given family, false otherwise.
  def shop_market_primary_family_member?(family)
    family.primary_person&.employee_roles.present? && account_holder_person == family.primary_person
  end

  # Checks if the account holder is an admin in the shop market.
  # A user is considered an admin in the shop market if they have an hbx staff role and they have the permission to modify a family.
  # TODO: We need to check if Primary Person's RIDP needs to be verified for Hbx Staff Admins
  #
  # @return [Boolean] Returns true if the account holder is an admin in the shop market, false otherwise.
  def shop_market_admin?
    hbx_role = account_holder_person.hbx_staff_role
    return false if hbx_role.blank?

    permission = hbx_role.permission
    return false if permission.blank?

    permission.modify_employer
  end

  def active_associated_shop_market_family_broker?(family)
    broker = account_holder_person&.broker_role
    broker_staff_roles = account_holder_person.broker_agency_staff_roles.where(aasm_state: 'active')

    return false if broker.blank? && broker_staff_roles.blank?
    return false unless broker.active? || broker.shop_market?
    return true if broker_profile_ids(family).include?(broker.benefit_sponsors_broker_agency_profile_id)

    broker_staff_roles.any? { |role| role.benefit_sponsors_broker_agency_profile_id == family_broker_agency_id }
  end

  def active_associated_shop_market_general_agency?(family)
    account_holder_ga_roles = account_holder_person&.active_general_agency_staff_roles
    return false if account_holder_ga_roles.blank?
    return false if broker_profile_ids(family).blank?

    ::SponsoredBenefits::Organizations::PlanDesignOrganization.where(
      :owner_profile_id.in => broker_profile_ids(family),
      :general_agency_accounts => {
        :"$elemMatch" => {
          aasm_state: :active,
          :benefit_sponsrship_general_agency_profile_id.in => account_holder_ga_roles.map(&:benefit_sponsors_general_agency_profile_id)
        }
      }
    ).present?
  end
  #
  # END - ACA Shop Market related methods

  # START - Non-ACA Fehb Market related methods
  #
  # Checks if the account holder is a primary family member in the Non-ACA Fehb market for the given family.
  # A user is considered a primary family member in the Non-ACA Fehb market if they are a primary family member in the ACA Shop market for the given family.
  #
  # @param family [Family] The family to check.
  # @return [Boolean] Returns true if the account holder is a primary family member in the Non-ACA Fehb market for the given family, false otherwise.
  def fehb_market_primary_family_member?(family)
    shop_market_primary_family_member?(family)
  end

  def fehb_market_admin?
    shop_market_admin?
  end

  def active_associated_fehb_market_family_broker?(_family)
    false
  end

  def active_associated_fehb_market_general_agency?(_family)
    false
  end
  #
  # END - Non-ACA Fehb Market related methods

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

  def read_all?
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

  def broker_profile_ids(family)
    @broker_profile_ids ||= ([family_broker_agency_id(family)] + employee_role_broker_agency_ids(family)).compact
  end

  def family_broker_agency_id(family)
    @family_broker_agency_id ||= family.current_broker_agency&.benefit_sponsors_broker_agency_profile_id
  end

  def employee_role_broker_agency_ids(family)
    @employee_role_broker_agency_ids ||= family.primary_person.active_employee_roles.map do |er|
      er.employer_profile&.active_broker_agency_account&.benefit_sponsors_broker_agency_profile_id
    end.compact
  end
end
