# frozen_string_literal: true

module Entities
  module CensusEmployees
    class CensusEmployee < Dry::Struct
      transform_keys(&:to_sym)

      attribute :first_name, Types::String.optional.meta(omittable: false)
      attribute :middle_name, Types::String.optional.meta(omittable: true)
      attribute :last_name, Types::String.optional.meta(omittable: false)
      attribute :name_sfx, Types::String.optional.meta(omittable: true)
      attribute :encrypted_ssn, Types::String.meta(omittable: false)
      attribute :gender, Types::String.optional.meta(omittable: false)
      attribute :dob, Types::Date.optional.meta(omittable: false)
      attribute :hired_on, Types::Date.optional.meta(omittable: false)
      attribute :aasm_state, Types::String.optional.meta(omittable: false)
      attribute :employee_relationship, Types::String.optional.meta(omittable: true)
      attribute :employer_assigned_family_id, Types::String.optional.meta(omittable: true)
      attribute :expected_selection, Types::String.optional.meta(omittable: true)
      attribute :employer_profile_id, Types::Bson.optional.meta(omittable: true)
      attribute :benefit_sponsors_employer_profile_id, Types::Bson.optional.meta(omittable: false)
      attribute :benefit_sponsorship_id, Types::Bson.optional.meta(omittable: false)
      attribute :employee_role_id, Types::Bson.optional.meta(omittable: true)
      attribute :cobra_begin_date, Types::Date.optional.meta(omittable: true)
      attribute :employment_terminated_on, Types::Date.optional.meta(omittable: true)
      attribute :coverage_terminated_on, Types::Date.optional.meta(omittable: true)
      attribute :is_business_owner, Types::Bool.optional.meta(omittable: true)
      attribute :no_ssn_allowed, Types::Strict::Bool.meta(omittable: true)
      attribute :census_dependents, Types::Array.of(Entities::CensusEmployees::CensusDependent).meta(omittable: true)
      attribute :address, Entities::Address.optional.meta(omittable: true)
      attribute :email, Entities::Email.optional.meta(omittable: true)
    end
  end
end
