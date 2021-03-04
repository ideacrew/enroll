# frozen_string_literal: true

module BenefitSponsors
  module Operations
    module Employers
      module Forms
        # New Staff operation is to initialize new employer staff with ability for self coverage
        # This will return an entity, which we use in our ERB files.
        class NewEmployerStaff
          include Dry::Monads[:result, :do, :try]

          def call(params)
            validated_params = yield validate(params)
            person = yield find_person(validated_params[:id])
            employer_staff_params = yield construct_employer_staff_params(person)
            staff_entity = yield get_staff_entity(employer_staff_params)

            Success(staff_entity.value!)
          end

          private

          def validate(params)
            if params[:id].present?
              Success(params)
            else
              Failure({:message => ['person_id is expected']})
            end
          end

          def find_person(id)
            ::Operations::People::Find.new.call({person_id: id})
          end

          def construct_employer_staff_params(person)
            home_address = person.home_address
            email = person.work_email || person.home_email
            Success(
              {
                person_id: person.id.to_s,
                first_name: person.first_name,
                last_name: person.last_name,
                dob: person.dob,
                email: person.work_email_or_best,
                area_code: person.work_phone&.area_code,
                number: person.work_phone&.number,
                coverage_record: {
                  ssn: person.ssn,
                  gender: person.gender,
                  dob: person.dob,
                  hired_on: nil,
                  is_applying_coverage: false,
                  has_other_coverage: false,
                  is_owner: false,
                  address: {
                    kind: 'home',
                    address_1: home_address&.kind,
                    address_2: home_address&.address_2,
                    address_3: home_address&.address_3,
                    city: home_address&.city,
                    county: home_address&.county,
                    state: home_address&.state,
                    location_state_code: home_address&.location_state_code,
                    full_text: home_address&.full_text,
                    zip: home_address&.zip,
                    country_name: home_address&.country_name
                  },
                  email: {
                    kind: email&.kind,
                    address: email&.address
                  }
                }
              }
            )
          end

          def get_staff_entity(params)
            Try do
              Success(BenefitSponsors::Entities::Forms::Employers::EmployerStaffRoles::New.new(params))
            end.or(Failure({:message => ['Invalid Params']}))
          end
        end
      end
    end
  end
end
