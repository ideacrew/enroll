class Ability
  include CanCan::Ability

  roles = User::ROLES.keys.map(&:to_s)

  def initialize(user)
    user ||= User.new

    alias_action :update, :destroy, :to => :modify

    if user.has_role? :employer_staff
      can :read, :all
    elsif user.has_role? :employee
      can :read, :all
    elsif user.has_role? :broker
      can :read, :all
    elsif user.has_role? :consumer
      can :read, :all
    elsif user.has_role? :resident
      can :read, :all
    elsif user.has_role? :hbx_staff
      can :read, :all
      can :edit_plan_year, PlanYear do |py|
        editable_plan_year?(py)
      end
    elsif user.has_role? :system_service
      can :read, :all
    elsif user.has_role? :web_service
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
