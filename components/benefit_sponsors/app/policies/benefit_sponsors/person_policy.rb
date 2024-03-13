# frozen_string_literal: true

module BenefitSponsors
  # Policy for person
  class PersonPolicy < ApplicationPolicy
    ACCESSABLE_ROLES = %w[hbx_staff_role broker_role active_broker_staff_roles].freeze

    def can_read_inbox?
      return true if can_hbx_staff_modify?
      return true if can_broker_modify?
      false
    end

    def can_active_broker_staff_role_modify?
      person = user&.person
      return false unless person.active_broker_staff_roles.present?
      person.active_broker_staff_roles.any? do |broker_staff_role|
        record&.broker_role&.benefit_sponsors_broker_agency_profile_id == broker_staff_role.benefit_sponsors_broker_agency_profile_id
      end
    end

    def can_broker_modify?
      (has_active_broker_role? || has_active_broker_agency_staff_role?) && matches_broker_agency_profile?(record&.broker_role&.benefit_sponsors_broker_agency_profile_id)
    end

    def matches_broker_agency_profile?(broker_agency_profile_id)
      Array(role).any? do |role|
        role.benefit_sponsors_broker_agency_profile_id == broker_agency_profile_id
      end
    end

    def can_hbx_staff_modify?
      role.is_a?(HbxStaffRole)
    end

    def has_active_broker_role?
      role.is_a?(::BrokerRole)
    end

    def has_active_broker_agency_staff_role?
      role.any? { |role| role.is_a?(::BrokerAgencyStaffRole) }
    end

    def role
      @role ||= find_role
    end

    def find_role
      person = user&.person
      return nil unless person
      ACCESSABLE_ROLES.detect do |role|
        return person.send(role) if person.respond_to?(role) && person.send(role)
      end

      nil
    end
  end
end
