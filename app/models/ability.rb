class Ability
  include CanCan::Ability

  roles = User::ROLES.keys.map(&:to_s)

  def initialize(user)
    user ||= User.new

    alias_action :update, :destroy, :to => :modify

    cannot :update, CensusEmployee do |employee|
      employee.dob_changed? or employee.ssn_changed?
    end
    cannot :delink, CensusEmployee

    if user.has_role? :employer_staff
      can :read, :all
      can :update, CensusEmployee# do |employee|
        # Do not enable editing on any other state without updating
        # model validation
      #  if employee.eligible?
      #    true
      #  end
      #end
    end
    if user.has_role? :employee
      can :read, :all
    end
    if user.has_role? :broker
      can :read, :all
      can :update, CensusEmployee
      can :delink, CensusEmployee do |employee|
        employee.employee_role_linked?
      end
    end
    if user.has_role? :broker_agency_staff
      can :read, :all
      can :update, :all
      can :delink, CensusEmployee do |employee|
        employee.employee_role_linked?
      end
    end
    if user.has_role? :consumer
      can :read, :all
    end
    if user.has_role? :resident
      can :read, :all
    end
    if user.has_role? :hbx_staff
      can :read, :all
      can :edit_plan_year, PlanYear do |py|
        editable_plan_year?(py)
      end
      can :update, CensusEmployee
      can :delink, CensusEmployee do |employee|
        employee.employee_role_linked?
      end
    end
    if user.has_role? :system_service
      can :read, :all
    end
    if user.has_role? :web_service
      can :read, :all
    end

  end

  #For controller action call authorize! :edit_plan_year
  #For view level <% if can? :edit_plan_year %>
  def editable_plan_year?(py)
    unless py.draft?
      raise CanCan::AccessDenied.new("Plan Year can no longer be updated", [:edit_plan_year], PlanYear)
    end

    true
  end
end
