# frozen_string_literal: true

module BenefitSponsors
  module Entities
    module Employers
      module EmployerStaffRoles
        # Create a object with coverage record dependent values
        class CoverageRecordDependent < Dry::Struct
          include Dry::StructExtended

          attribute :ssn, Types::String.optional
          attribute :dob, Types::Date.optional
          attribute :gender, Types::String.optional
          attribute :first_name, Types::String.optional
          attribute :middle_name, Types::String.optional
          attribute :last_name, Types::String.optional
          attribute :employee_relationship, Types::String.optional
        end
      end
    end
  end
end
