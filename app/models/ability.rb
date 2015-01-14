class Ability
  include CanCan::Ability

  roles = User::ROLES.keys.map(&:to_s)

  def initialize(user)
    user ||= User.new

    alias_action :update, :destroy, :to => :modify

    if user.role == roles[0] # employer
      can :read, :all
    elsif user.role == roles[1] #employee
      can :read, :all
    elsif user.role == roles[2] #broker
      can :read, :all
    elsif user.role == roles[3] #undocumented_consumer
      can :read, :all
    elsif user.role == roles[4] # qhp_consumer
      can :read, :all
    elsif user.role == roles[5] # hbx_employee
      can :read, :all
    elsif user.role == roles[6] # system_service
      can :read, :all
    elsif user.role == roles[7] # web_service
      can :read, :all
    end

  end
end