class ApplicationPolicy
  attr_reader :user, :record

  def initialize(user, record)
    @user = user
    @record = record
  end

  def individual_market_primary_family_member?(family)
    (family.primary_person.consumer_role.present? || family.primary_person.resident_role.present?) && user == family.primary_person.user
  end

  def active_associated_family_broker?(family)
    broker = user.person.broker_role
    return false if broker.blank? || !broker.active?

    broker_agency_account = family.active_broker_agency_account
    return false if broker_agency_account.blank?

    broker_agency_account.benefit_sponsors_broker_agency_profile_id == broker.benefit_sponsors_broker_agency_profile_id &&
      broker_agency_account.writing_agent_id == broker.id
  end

  def ridp_verified_primary_person?(family)
    consumer_role = family.primary_person.consumer_role
    # For Employee Role and Resident Role we don't need to check for RIDP verification.
    # Also, we should not block the roles because of RIDP Verification check.
    return true if consumer_role.blank?

    consumer_role.identity_verified?
  end

  def hbx_staff_admin?
    user.person.hbx_staff_role&.permission&.modify_family
  end

  def individual_market_admin?
    hbx_staff_admin?
  end

  def shop_market_admin?
    user.person.hbx_staff_role&.permission&modify_employer
  end

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
end
