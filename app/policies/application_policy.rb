class ApplicationPolicy
  attr_reader :user, :record

  def initialize(user, record)
    @user = user
    @record = record
  end

  def individual_market_primary_family_member?
  end

  def shop_market_primary_family_member?
  end

  def fehb_market_primary_family_member?
  end
  
  def active_family_broker?
  end

  def individual_market_admin?
  end

  def shop_market_admin?
  end

  def fehb_market_admin?
  end

  def general_agency_staff?
  end

  def index?
    read_all?
  end

  def show?

    # scope.where(:id => record.id).exists?
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
