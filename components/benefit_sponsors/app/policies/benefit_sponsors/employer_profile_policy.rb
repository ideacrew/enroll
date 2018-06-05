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

    def coverage_reports?
      return false unless user.present?
      return true if (user.has_hbx_staff_role? && can_list_enrollments?) || is_broker_for_employer?(record) || is_general_agency_staff_for_employer?(record)
      # TODO
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

    def list_enrollments?
      coverage_reports?
    end

    def can_list_enrollments?
      user.person.hbx_staff_role.permission.list_enrollments
    end
  end
end
