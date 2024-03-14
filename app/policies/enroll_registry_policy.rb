# frozen_string_literal: true

# Permission checks for EnrollRegistry.
class EnrollRegistryPolicy < ApplicationPolicy
  # Can I see the EnrollRegistry settings?
  def show?
    return false if ENV['AWS_ENV'] == 'prod'

    return false if account_holder_person.blank?

    account_holder_person.hbx_staff_role.present?
  end
end