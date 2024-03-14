module BenefitSponsors
  module Organizations
    module OrganizationForms
      class StaffRoleFormPolicy < ApplicationPolicy

        attr_reader :service

        def initialize(user, record)
          super
          @service = BenefitSponsors::Services::StaffRoleService.new(
              profile_id: record.profile_id
          )
        end

        def create?
          return true if can_edit?
        end

        def edit?
          return true if can_edit?
        end

        def destroy?
          return false if current_user_is_form_subject?
          return false if primary_broker_is_form_subject?

          return true if can_edit?
        end

        def approve?
          return true if can_edit?
        end

        def admin?
          user.has_hbx_staff_role? && user.person && user.person.hbx_staff_role.permission.modify_employer
        end

        def profile
          @profile ||= service.find_profile(record)
        end

        def can_edit?
          reg_service = Services::NewProfileRegistrationService.new(profile_id: record.profile_id)
          if profile.is_a?(BrokerAgencyProfile)
            # BrokerAgencyProfilePolicy has a different level of access than EmployerProfile and GeneralAgencyProfile
            BenefitSponsors::Organizations::BrokerAgencyProfilePolicy.new(account_holder, profile).access_to_broker_agency_profile?
          elsif profile.is_a?(GeneralAgencyProfile)
            return true if admin?
            return false if user.person.general_agency_primary_staff.blank?
            return true if Person.staff_for_ga(profile).include?(user.person)
          else
            return true if admin?
            return true if reg_service.is_broker_for_employer?(user, record) || reg_service.is_general_agency_staff_for_employer?(user, record)
            return true if Person.staff_for_employer(profile).include?(user.person)
          end
        end

        private

        def current_user_is_form_subject?
          # because this form is used by multiple Profile Types, we want to ignore the other types
          return false unless profile.is_a?(BrokerAgencyProfile)

          # person_id on the record is stored as a string
          account_holder&.person.id.to_str == record&.person_id
        end

        def primary_broker_is_form_subject?
          return false unless profile.is_a?(BrokerAgencyProfile)

          # person_id on the record is stored as a string
          profile&.primary_broker_role&.person.id.to_str == record&.person_id
        end
      end
    end
  end
end
