class ApplicationPolicy
  attr_reader :user, :record, :current_person

  def initialize(user, record)
    @user = user
    @record = record
    @current_person = user&.person
  end

  def current_person
    @current_person ||= user.person
  end

  # TODO: Remove the following line after the complete implementation of the methods
  # MARCO's reference commit - https://github.com/ideacrew/enroll/commit/d70f1722dc9c8cc27d3ccdc9a5b1e77e2d34c7d8

  # START - Individual Market related methods
  def individual_market_primary_family_member?(family)
    family.primary_consumer && current_person == family.primary_person
  end

  def active_associated_individual_market_family_broker?(family)
    return false unless family.primary_consumer

    broker = current_person.broker_role
    return false if broker.blank? || !broker.active? || !broker.individual_market?
    return false if (broker_role.blank? || !broker_role.active?) && broker_staff_roles.blank?
    return false if broker_profile_ids(family).blank?

    broker_profile_ids(family).include?(broker_role.benefit_sponsors_broker_agency_profile_id) || broker_staff_roles.map(&:benefit_sponsors_broker_agency_profile_id).include?(ivl_broker_agency_id(family))
  end

  # Checks if the user is associated with an active general agency for the given family.
  # A user is considered associated with an active general agency if the broker is not blank, is active,
  # and matches the general agency associated with the active broker agency account of the family.
  #
  # @param family [Family] The family to check.
  # @return [Boolean] Returns true if the user is associated with an active broker for the family, false otherwise.
  def active_associated_family_general_agency?(family)
    return false unless current_person

    ga_roles = current_person&.active_general_agency_staff_roles
    return false if ga_roles.blank?
    return false if broker_profile_ids(family).blank?

    ::SponsoredBenefits::Organizations::PlanDesignOrganization.where(
      :owner_profile_id.in => broker_profile_ids(family),
      :general_agency_accounts => {
        :"$elemMatch" => {
          aasm_state: :active,
          :benefit_sponsrship_general_agency_profile_id.in => ga_roles.map(&:benefit_sponsors_general_agency_profile_id)
        }
      }
    ).present?
  end

  def individual_market_admin?(family)
    family.primary_consumer && current_person.hbx_staff_role&.permission&.modify_family
  end
  # END - Individual Market related methods

  # START - Coverall Market related methods
  def coverall_market_primary_family_member?(family)
    family.primary_resident && current_person == family.primary_person
  end

  # Checks if the user is a shop market admin.
  # A user is considered a shop market admin if they are an hbx staff modify family.
  #
  # @return [Boolean, nil] Returns true if the user is a shop market admin,
  # false if they are not, or nil if the user or their permissions are not defined.
  def shop_market_admin?
    current_person.hbx_staff_role&.permission&.modify_employer
  end
  def active_associated_coverall_market_family_broker?(family)
    return false unless family.primary_resident

    broker = current_person.broker_role
    return false if broker.blank? || !broker.active? || !broker.individual_market?

    broker_agency_account = family.active_broker_agency_account
    return false if broker_agency_account.blank?

    broker_agency_account.benefit_sponsors_broker_agency_profile_id == broker.benefit_sponsors_broker_agency_profile_id &&
      broker_agency_account.writing_agent_id == broker.id
  end

  def coverall_market_admin?(family)
    family.primary_resident && current_person.hbx_staff_role&.permission&.modify_family
  end
  # END - Coverall Market related methods

  # START - Shop Market related methods
  def shop_market_primary_family_member?(family)
    family.primary_person.employee_roles.present? && current_person == family.primary_person
  end
  # END - Shop Market related methods

  # START - Fehb Market related methods
  def fehb_market_primary_family_member?(family)
    shop_market_primary_family_member?(family)
  end
  # END - Fehb Market related methods

  def can_access_individual_market_family_without_ridp?(family)
    individual_market_primary_family_member?(family) || individual_market_admin? || active_associated_family_broker?(family)
  end

  def can_access_individual_market_family?(family)
    ridp_verified_primary_person?(family) &&
      (
        individual_market_primary_family_member?(family) ||
          active_associated_family_broker?(family) ||
          individual_market_admin?
      )
  end

  def can_access_shop_market_family?(family)
    shop_market_primary_family_member?(family) || shop_market_admin? || active_associated_family_broker?(family) || active_associated_family_general_agency?(family)
  end

  def can_access_fehb_market_family?(family)
    fehb_market_primary_family_member?(family) || shop_market_admin? || active_associated_family_broker?(family) || active_associated_family_general_agency?(family)
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
    current_person.hbx_staff_role&.permission&.modify_family
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
    @broker_profile_ids ||= ([ivl_broker_agency_id(family)] + shop_broker_agency_ids(family)).compact
  end

  def ivl_broker_agency_id(family)
    @ivl_broker_agency_id ||= family.current_broker_agency&.benefit_sponsors_broker_agency_profile_id
  end

  def shop_broker_agency_ids(family)
    @shop_broker_agency_ids ||= family.primary_person.active_employee_roles.map do |er|
      er.employer_profile&.active_broker_agency_account&.benefit_sponsors_broker_agency_profile_id
    end.compact
  end
end
