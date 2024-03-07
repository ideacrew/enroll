class ApplicationPolicy
  attr_reader :user, :record

  def initialize(user, record)
    @user = user
    @record = record
  end

  # Checks if the primary person of the given family is an individual market primary family member.
  # A primary person is considered an individual market primary family member if they have either a consumer role or a resident role,
  # and the user is the same as the user of the primary person.
  #
  # @param family [Family] The family to check.
  # @return [Boolean] Returns true if the primary person of the family is an individual market primary family member, false otherwise.
  def individual_market_primary_family_member?(family)
    (family.primary_person.consumer_role.present? || family.primary_person.resident_role.present?) && user == family.primary_person.user
  end

  # Checks if the user is associated with an active broker for the given family.
  # A user is considered associated with an active broker if the broker is not blank, is active,
  # and matches the broker associated with the active broker agency account of the family.
  #
  # @param family [Family] The family to check.
  # @return [Boolean] Returns true if the user is associated with an active broker for the family, false otherwise.
  def active_associated_family_broker?(family)
    broker = user.person.broker_role
    return false if broker.blank? || !broker.active?

    broker_agency_account = family.active_broker_agency_account
    return false if broker_agency_account.blank?

    broker_agency_account.benefit_sponsors_broker_agency_profile_id == broker.benefit_sponsors_broker_agency_profile_id &&
      broker_agency_account.writing_agent_id == broker.id
  end

  # Checks if the primary person of the given family has their identity verified.
  # For Employee Role and Resident Role, RIDP verification is not required.
  # Also, roles should not be blocked because of RIDP Verification check.
  #
  # @param family [Family] The family to check.
  # @return [Boolean] Returns true if the primary person of the family has their identity verified or if the consumer role is blank, false otherwise.
  def ridp_verified_primary_person?(family)
    consumer_role = family.primary_person.consumer_role
    return true if consumer_role.blank?

    consumer_role.identity_verified?
  end

  # Checks if the user is an individual market admin.
  # A user is considered an individual market admin if they are an hbx staff modify family.
  #
  # @return [Boolean, nil] Returns true if the user is an individual market admin,
  # false if they are not, or nil if the user or their permissions are not defined.
  def individual_market_admin?
    hbx_staff_modify_family?
  end

  # Checks if the user is a shop market admin.
  # A user is considered a shop market admin if they are an hbx staff modify family.
  #
  # @return [Boolean, nil] Returns true if the user is a shop market admin,
  # false if they are not, or nil if the user or their permissions are not defined.
  def shop_market_admin?
    user.person.hbx_staff_role&.permission&.modify_employer
  end

  # Checks if the user is a fehb market admin.
  # A user is considered a fehb market admin if they are an hbx staff modify family.
  #
  # @return [Boolean, nil] Returns true if the user is a fehb market admin,
  # false if they are not, or nil if the user or their permissions are not defined.
  def fehb_market_admin?
    shop_market_admin?
  end

  def shop_market_primary_family_member?(family)
    family.primary_person.employee_roles.present? && user == family.primary_person.user
  end

  def fehb_market_primary_family_member?(family)
    shop_market_primary_family_member?(family)
  end

  def general_agency_staff?
    false
  end

  def can_authorize_individual_market_family?(family)
    ridp_verified_primary_person?(family) &&
      (
        individual_market_primary_family_member?(family) ||
          active_associated_family_broker?(family) ||
          individual_market_admin?
      )
  end

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

  # Checks if the user is an hbx staff modify family.
  # A user is considered an hbx staff modify family if they have the permission to modify a family.
  #
  # @return [Boolean, nil] Returns true if the user is an hbx staff modify family,
  # false if they are not, or nil if the user or their permissions are not defined.
  def hbx_staff_modify_family?
    user.person.hbx_staff_role&.permission&.modify_family
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
end
