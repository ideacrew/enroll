class ApplicationPolicy
  attr_reader :user, :record

  def initialize(user, record)
    @user = user
    @record = record
  end

  def account_holder
    user
  end

  def account_holder_person
    @account_holder_person ||= account_holder.person
  end

  def individual_market_role
    @individual_market_role ||= account_holder_person&.consumer_role
  end

  def coverall_market_role
    @coverall_market_role ||= account_holder_person&.resident_role
  end

  def account_holder_family
    @account_holder_family ||= account_holder_person&.primary_family
  end

  # START - ACA Individual Market related methods
  def individual_market_primary_family_member?(family)
    individual_market_ridp_verified? && (account_holder_family == family)
  end

  def individual_market_non_ridp_primary_family_member?(family)
    individual_market_role && (account_holder_family == family)
  end

  def individual_market_ridp_verified?
    individual_market_role&.identity_verified?
  end

  # TODO: We need to check if Primary Person's RIDP needs to be verified for Brokers
  def active_associated_individual_market_family_broker?(family)
    broker = account_holder_person.broker_role
    return false if broker.blank? || !broker.active? || !broker.individual_market?

    broker_agency_account = family.active_broker_agency_account
    return false if broker_agency_account.blank?

    broker_agency_account.benefit_sponsors_broker_agency_profile_id == broker.benefit_sponsors_broker_agency_profile_id &&
      broker_agency_account.writing_agent_id == broker.id
  end

  # TODO: We need to check if Primary Person's RIDP needs to be verified for Hbx Staff Admins
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

  # END - ACA Individual Market related methods

  # START - Non-ACA Coverall Market related methods
  def coverall_market_primary_family_member?(family)
    coverall_market_role && account_holder_person == family.primary_person
  end

  def active_associated_coverall_market_family_broker?(family)
    return false unless coverall_market_role

    broker = account_holder_person.broker_role
    return false if broker.blank? || !broker.active? || !broker.individual_market?

    broker_agency_account = family.active_broker_agency_account
    return false if broker_agency_account.blank?

    broker_agency_account.benefit_sponsors_broker_agency_profile_id == broker.benefit_sponsors_broker_agency_profile_id &&
      broker_agency_account.writing_agent_id == broker.id
  end

  def coverall_market_admin?(family)
    coverall_market_role && account_holder_person.hbx_staff_role&.permission&.modify_family
  end
  # END - Non-ACA Coverall Market related methods

  # START - ACA Shop Market related methods
  def shop_market_primary_family_member?(family)
    family.primary_person.employee_roles.present? && account_holder_person == family.primary_person
  end
  # END - ACA Shop Market related methods

  # START - Non-ACA Fehb Market related methods
  def fehb_market_primary_family_member?(family)
    shop_market_primary_family_member?(family)
  end
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
end
