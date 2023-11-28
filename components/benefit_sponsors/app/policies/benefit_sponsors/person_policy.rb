# frozen_string_literal: true

module BenefitSponsors
  # Policy for person
  class PersonPolicy < ApplicationPolicy
    def can_read_inbox?
      return true if user.person.hbx_staff_role
      return true if (user.person&.broker_role || record.broker_role) && (user.person.id == record.id)
      false
    end
  end
end
