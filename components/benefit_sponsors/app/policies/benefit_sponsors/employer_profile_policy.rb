module BenefitSponsors
  class EmployerProfilePolicy < ApplicationPolicy

    def show?
      return false unless user.present?
      return true if user.has_hbx_staff_role? || is_broker_for_employer?(record) || is_general_agency_staff_for_employer?(record)
      true
    end

    def show_pending?
      return false unless user.present?
      true
    end

    def coverage_reports?
      return false unless user.present?
      return true if (user.has_hbx_staff_role? && can_list_enrollments?) || is_broker_for_employer?(record) || is_general_agency_staff_for_employer?(record)
      true
    end

    def export_census_employees?
      show?
    end

    def inbox?
      show?
    end

    def is_broker_for_employer?(profile)
      broker_role = user.person.broker_role
      return false unless broker_role
      profile.broker_agency_accounts.any? {|acc| acc.writing_agent_id == broker_role.id}
    end

    def is_general_agency_staff_for_employer?(profile)
      # TODO
      return false
    end

    def updateable?
      if role = user.person.hbx_staff_role
        role.permission.modify_employer
      else
        user.person.employer_staff_roles.any? do |employer_staff_role|
          employer_staff_role.benefit_sponsor_employer_profile_id == record.id
        end
      end
    end

    def list_enrollments?
      coverage_reports?
    end

    def can_list_enrollments?
      user.person.hbx_staff_role.permission.list_enrollments
    end
  end
end
