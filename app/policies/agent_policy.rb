# frozen_string_literal: true

#AgentPolicy
class AgentPolicy < ApplicationPolicy
  def initialize(user, _record)
    super
    @person = user.person
  end

  def home?
    return true if @person.csr_role
    return true if @person.assister_role

    false
  end

  def inbox?
    home?
  end
end
