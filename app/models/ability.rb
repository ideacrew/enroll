class Ability
  include CanCan::Ability

  roles = User::ROLES.keys.map(&:to_s)

  def initialize(user)
    user ||= User.new

    alias_action :update, :destroy, :to => :modify

    if user.has_role? :employer
      can :read, :all
    elsif user.has_role? :employee
      can :read, :all
    elsif user.has_role? :broker
      can :read, :all
    elsif user.has_role? :undocumented_consumer
      can :read, :all
    elsif user.has_role? :qhp_consumer
      can :read, :all
    elsif user.has_role? :hbx_employee
      can :read, :all
    elsif user.has_role? :system_service
      can :read, :all
    elsif user.has_role? :web_service
      can :read, :all
    end

  end
end
