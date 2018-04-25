module BenefitSponsors
  module Organizations
    module Forms
      class RegistrationFormPolicy < ApplicationPolicy

        attr_reader :service

        def initialize(user, record)
          super
          @service = Services::NewProfileRegistrationService.new(profile_id: record.organization.profile.id)
        end

        def new?
          true
        end

        def create?
          return true unless role = user && user.person && user.person.hbx_staff_role
          role.permission.modify_employer
        end

        def edit?
          true
        end

        def update?
          return false unless can_modify_employer?
          can_update_profile?
        end

        def can_modify_employer?
          return false unless user.person.present?
          user.person.agent? || user.permission.modify_employer
        end

        def can_update_profile?
          # Get from service object based on profile type
          true
        end
      end
    end
  end
end
