# frozen_string_literal: true

module BenefitSponsors
  module Operations
    module Employers
      module EmployerStaffRoles
        # New Staff operation is to initialize new employer staff with ability for self coverage
        # This will return an entity
        class Create
          include Dry::Monads[:result, :do, :try]

          def call(params:, profile:)
            return Failure({:message => 'Invalid profile'}) if profile.blank? || !profile.is_a?(BenefitSponsors::Organizations::AcaShopDcEmployerProfile)

            constructed_params = yield construct_params(params[:coverage_record], profile)
            values = yield validate(constructed_params)
            employer_staff_entity = yield persist(values)

            Success(employer_staff_entity)
          end

          private

          def construct_params(params, profile)
            address = params[:address]
            email = params[:email]
            Success({
                      is_owner: false,
                      benefit_sponsor_employer_profile_id: profile.id,
                      aasm_state: 'is_applicant',
                      coverage_record: {
                        ssn: params[:ssn],
                        gender: params[:gender],
                        dob: params[:dob].present? ? params[:dob] : nil,
                        hired_on: params[:hired_on].present? ? parse_date(params[:hired_on]) : nil,
                        is_applying_coverage: params[:is_applying_coverage] == "true",
                        is_owner: params[:is_owner] == "true",
                        has_other_coverage: params[:has_other_coverage] == "true",
                        address: {
                          kind: address[:kind],
                          address_1: address[:kind],
                          address_2: address[:address_2],
                          address_3: address[:address_3],
                          city: address[:city],
                          county: address[:county],
                          state: address[:state],
                          location_state_code: address[:location_state_code],
                          full_text: address[:full_text],
                          zip: address[:zip],
                          country_name: address[:country_name]
                        },
                        email: {
                          kind: email[:kind],
                          address: email[:address]
                        },
                        coverage_record_dependents: params[:coverage_record_dependents]
                      }
                    })
          end

          def validate(constructed_params)
            result = BenefitSponsors::Validators::Employers::EmployerStaffRoles::EmployerStaffRoleContract.new.call(constructed_params)
            if result.success?
              Success(result.to_h)
            else
              Failure({message: 'Unable to build Employer staff role'})
            end
          end

          def persist(values)
            Success(BenefitSponsors::Entities::Employers::EmployerStaffRoles::EmployerStaffRole.new(values))
          end

          def parse_date(date)
            return date if date.is_a? Date
            Date.strptime(date, '%m/%d/%Y')
          end
        end
      end
    end
  end
end
