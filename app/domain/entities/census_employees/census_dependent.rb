# frozen_string_literal: true

module Entities
  module CensusEmployees
    class CensusDependent < Dry::Struct
      transform_keys(&:to_sym)

      attribute :first_name, Types::String.optional
      attribute :middle_name, Types::String.optional.meta(omittable: true)
      attribute :last_name, Types::String.optional
      attribute :name_sfx, Types::String.optional.meta(omittable: true)
      attribute :encrypted_ssn, Types::String.optional.meta(omittable: true)
      attribute :gender, Types::String.optional
      attribute :dob, Types::Date.optional
      attribute :employee_relationship, Types::String.optional.meta(omittable: true)
      attribute :employer_assigned_family_id, Types::String.optional.meta(omittable: true)
    end
  end
end
