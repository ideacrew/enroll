# frozen_string_literal: true

module BenefitSponsors
  module Entities
    module Employers
      module EmployerStaffRoles
        # Create a object with coverage record values
        class CoverageRecord < Dry::Struct
          include Dry::StructExtended

          attribute :ssn, Types::String.optional
          attribute :dob, Types::Date.optional
          attribute :hired_on, Types::Date.optional
          attribute :gender, Types::String.optional
          attribute :is_applying_coverage, Types::Bool
          attribute :has_other_coverage, Types::Bool
          attribute :is_owner, Types::Bool
          attribute :address, BenefitSponsors::Entities::Address
          attribute :email, BenefitSponsors::Entities::Email
          attribute :coverage_record_dependents, Types::Array.of(::BenefitSponsors::Entities::Employers::EmployerStaffRoles::CoverageRecordDependent).optional
        end
      end
    end
  end
end