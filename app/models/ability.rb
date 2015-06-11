class Ability
  include CanCan::Ability

  roles = User::ROLES.keys.map(&:to_s)

  def initialize(user)
    user ||= User.new

    alias_action :update, :destroy, :to => :modify

    cannot :update, EmployerCensus::Employee do |employee|
      employee.dob_changed? or employee.ssn_changed?
    end

    if user.has_role? :employer_staff
      can :read, :all
      can :update, EmployerCensus::Employee do |employee|
        if employee.is_linkable?
          true
        else
          !(employee.dob_changed? or employee.ssn_changed?)
        end
      end
    end
    if user.has_role? :employee
      can :read, :all
    end
    if user.has_role? :broker
      can :read, :all
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
      can :update, EmployerCensus::Employee
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
