module BenefitSponsors
  module Forms
    class BenefitApplicationFormPolicy < ApplicationPolicy

      def initialize(current_user, benefit_application_form)
        @user = current_user
        @benefit_application_form = benefit_application_form
        @service = BenefitSponsors::Services::BenefitApplicationService.new
      end

      #TODO
      def new?
        true
      end

      def create?
        true
      end

      def edit?
        true
      end

      def update?
        true
      end
    end
  end
end
