# frozen_string_literal: true

module FinancialAssistance
  module Locations
    # The AddressPolicy class defines the policy for accessing and modifying addresses.
    # It determines what actions a user can perform on an address based on their roles and permissions.
    class AddressPolicy < ::ApplicationPolicy

      # Initializes the AddressPolicy with a user and a record.
      # It sets the @family instance variable to the family of the address record.
      #
      # @param user [User] the user who is performing the action
      # @param record [Address] the address that the user is trying to access or modify
      # @attr [Family] @family the family of the address record
      def initialize(user, record)
        super
        @family ||= record.applicant.application.family
      end

      # Determines if the current user has permission to destroy the address.
      # The user can destroy the address if they are a primary family member,
      # an admin, an active associated broker staff, or an active associated broker in the individual market.
      #
      # @return [Boolean] Returns true if the user is a primary family member, an admin,
      # an active associated broker staff, or an active associated broker in the individual market.
      # Returns false otherwise.
      def destroy?
        return true if individual_market_primary_family_member?
        return true if active_associated_individual_market_family_broker_staff?
        return true if active_associated_individual_market_family_broker?
        return true if individual_market_admin?

        false
      end
    end
  end
end
