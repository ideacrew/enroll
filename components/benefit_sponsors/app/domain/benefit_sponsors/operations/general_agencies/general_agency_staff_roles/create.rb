# frozen_string_literal: true

module BenefitSponsors
  module Operations
    module GeneralAgencies
      module GeneralAgencyStaffRoles
        # New Staff operation is to initialize new ga staff
        # This will return an entity
        class Create
          include Dry::Monads[:result, :do, :try]

          def call(profile:, npn: nil)
            return Failure({:message => 'Invalid profile'}) if profile.blank? || !profile.is_a?(BenefitSponsors::Organizations::GeneralAgencyProfile)

            constructed_params = yield construct_params(profile, npn)
            values = yield validate(constructed_params)
            ga_staff_entity = yield persist(values)

            Success(ga_staff_entity)
          end

          private

          def construct_params(profile, npn)
            Success({
                      benefit_sponsors_general_agency_profile_id: profile.id,
                      npn: npn,
                      aasm_state: 'general_agency_pending'
                    })
          end

          def validate(constructed_params)
            result = BenefitSponsors::Validators::GeneralAgencies::GeneralAgencyStaffRoles::GeneralAgencyStaffRoleContract.new.call(constructed_params)
            if result.success?
              Success(result.to_h)
            else
              Failure({:message => 'Unable to build general agency staff role'})
            end
          end

          def persist(values)
            Success(BenefitSponsors::Entities::GeneralAgencies::GeneralAgencyStaffRoles::GeneralAgencyStaffRole.new(values))
          end
        end
      end
    end
  end
end
