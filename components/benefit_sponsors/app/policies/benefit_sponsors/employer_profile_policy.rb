module BenefitSponsors
  class EmployerProfilePolicy < ApplicationPolicy

    def show?
      return false unless user.present?
      return true if user.has_hbx_staff_role? || is_broker_for_employer?(record) || is_general_agency_staff_for_employer?(record)
      # TODO
      true
    end

    def show_pending?
      return false unless user.present?
      true
    end

    def is_broker_for_employer?(profile)
      # TODO
      return true
    end

    def is_general_agency_staff_for_employer?(profile)
      # TODO
      return true
    end

    def updateable?
      return true unless role = user.person && user.person.hbx_staff_role
      role.permission.modify_employer
    end
  end
end
