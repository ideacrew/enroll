class ApplicationPolicy
  attr_reader :user, :record

  def initialize(user, record)
    @user = user
    @record = record
  end

  def current_person
    @current_person ||= user.person
  end

  # TODO Remove the following line after the complete implementation of the methods
  # MARCO's reference commit - https://github.com/ideacrew/enroll/commit/d70f1722dc9c8cc27d3ccdc9a5b1e77e2d34c7d8

  # START - Individual Market related methods
  def individual_market_primary_family_member?(family)
    family.primary_consumer && current_person == family.primary_person
  end

  def active_associated_individual_market_family_broker?(family)
    return false unless family.primary_consumer

    broker = current_person.broker_role
    return false if broker.blank? || !broker.active? || !broker.individual_market?

    broker_agency_account = family.active_broker_agency_account
    return false if broker_agency_account.blank?

    broker_agency_account.benefit_sponsors_broker_agency_profile_id == broker.benefit_sponsors_broker_agency_profile_id &&
      broker_agency_account.writing_agent_id == broker.id
  end

  def individual_market_admin?(family)
    family.primary_consumer && current_person.hbx_staff_role&.permission&.modify_family
  end
  # END - Individual Market related methods

  # START - Coverall Market related methods
  def coverall_market_primary_family_member?(family)
    family.primary_resident && current_person == family.primary_person
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
