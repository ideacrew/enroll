# frozen_string_literal: true

module BenefitSponsors
  # Policy for person
  class PersonPolicy < ::ApplicationPolicy
    def can_read_inbox?
      return true if user.person.hbx_staff_role
      return true if (user.person&.broker_role || record.broker_role) && (user.person.id == record.id)
      false
    end

    # Determines whether the inbox message should be shown.
    #
    # @return [Boolean] `true` if the inbox message should be shown, `false` otherwise.
    def show_inbox_message?
      destroy_inbox_message?
    end

    # Determines if the current user has permission to destroy an inbox message.
    # The user can destroy an inbox message if they are the person associated with the record,
    # an admin in the shop market, or a broker agency staff member associated with the broker agency of the record.
    # This method currently only supports people with broker roles.
    #
    # @return [Boolean] Returns true if the user has permission to destroy an inbox message, false otherwise.
    # @note This method is implemented for the destroy action in the messages controller.
    def destroy_inbox_message?
      broker = record.broker_role
      broker_staff_roles = account_holder_person&.broker_agency_staff_roles&.active

      return false if broker.blank?

      # Current User Person same as the record(person).
      return true if account_holder_person == record

      # Current User is HbxStaffAdmin.
      return true if shop_market_admin?

      # Current User is Broker Agency Staff.
      return true if broker_staff_roles&.any? { |role| role&.broker_agency_profile_id == broker.broker_agency_profile_id }

      false
    end
  end
end
