# frozen_string_literal: true

module BenefitSponsors
  module Entities
    module Forms
      module Employers
        module EmployerStaffRoles
          # Entity to initialize while showing employer staff record.
          class New < Dry::Struct
            transform_keys(&:to_sym)

            attribute :person_id,            Types::String
            attribute :first_name,           Types::String
            attribute :last_name,            Types::String
            attribute :dob,                  Types::Date.meta(omittable: true)
            attribute :email,                Types::String.optional.meta(omittable: true)
            attribute :area_code,            Types::String.optional.meta(omittable: true)
            attribute :number,               Types::String.optional.meta(omittable: true)
            attribute :coverage_record,      Dry::Struct.meta(omittable: true) do
              attribute :ssn,                    Types::String.optional.meta(omittable: true)
              attribute :gender,                 Types::String.optional.meta(omittable: true)
              attribute :dob,                    Types::Date.optional.meta(omittable: true)
              attribute :hired_on,               Types::Date.optional.meta(omittable: true)
              attribute :is_applying_coverage,   Types::Bool.optional.meta(omittable: true)
              attribute :has_other_coverage,     Types::Bool.optional.meta(omittable: true)
              attribute :is_owner,               Types::Bool.optional.meta(omittable: true)
              attribute :address,                BenefitSponsors::Entities::Address.optional.meta(omittable: true)
              attribute :email,                  BenefitSponsors::Entities::Email.optional.meta(omittable: true)
              attribute :census_dependents,      Types::Array.of(::BenefitSponsors::Entities::Employers::EmployerStaffRoles::CoverageRecordDependent).optional.meta(omittable: true)
            end
          end
        end
      end
    end
  end
end
