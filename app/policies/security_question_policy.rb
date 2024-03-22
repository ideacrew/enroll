# frozen_string_literal: true

# Policy class for security questions.
# Currently, this feature is turned off for both ME and DC and this is the reason all the policies are literally returning false.
# In future when we enable the feature for a client then we should implement the access rules/permission.
#
# @note This class inherits from ApplicationPolicy.
class SecurityQuestionPolicy < ApplicationPolicy
  # Determines if the user can view the index page of security questions.
  # @return [Boolean] Returns false as this feature is currently turned off.
  def index?
    false
  end

  # Determines if the user can view the new security question page.
  # @return [Boolean] Returns false as this feature is currently turned off.
  def new?
    index?
  end

  # Determines if the user can create a new security question.
  # @return [Boolean] Returns false as this feature is currently turned off.
  def create?
    index?
  end

  # Determines if the user can view the edit security question page.
  # @return [Boolean] Returns false as this feature is currently turned off.
  def edit?
    index?
  end

  # Determines if the user can update a security question.
  # @return [Boolean] Returns false as this feature is currently turned off.
  def update?
    index?
  end

  # Determines if the user can destroy a security question.
  # @return [Boolean] Returns false as this feature is currently turned off.
  def destroy?
    index?
  end
end
