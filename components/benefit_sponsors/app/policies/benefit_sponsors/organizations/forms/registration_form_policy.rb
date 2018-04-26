module BenefitSponsors
  module Organizations
    module Forms
      class RegistrationFormPolicy < ApplicationPolicy

        attr_reader :service

        def initialize(user, record)
          super
          @service = Services::NewProfileRegistrationService.new(
            profile_id: record.organization.profile.id,
            profile_type: record.profile_type
          )
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
          return true unless role = user && user.person && user.person.hbx_staff_role
          role.permission.modify_employer
        end

        def can_update_profile?
          # Get from service object based on profile type
          true
        end

        def is_broker_profile?
          profile_type == "broker_agency"
        end

        def is_employer_profile?
          profile_type == "benefit_sponsor"
        end

        def profile_type
          service.profile_type
        end
      end
    end
  end
end
