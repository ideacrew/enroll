module BenefitSponsors
  module Forms
    class BenefitApplicationFormPolicy < ApplicationPolicy

      def initialize(current_user, benefit_application_form)
        @user = current_user
        @benefit_application_form = benefit_application_form
        @service = BenefitSponsors::Services::BenefitApplicationService.new
      end

      def updateable?
        return true unless role = user.person && user.person.hbx_staff_role
        role.permission.modify_employer
      end

      def revert_application?
        return true unless role = user.person && user.person.hbx_staff_role
        role.permission.revert_application
      end
    end
  end
end
