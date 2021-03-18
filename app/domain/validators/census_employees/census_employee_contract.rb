# frozen_string_literal: true

module Validators::CensusEmployees
  class CensusEmployeeContract < Dry::Validation::Contract

    params do
      required(:first_name).maybe(:string)
      optional(:middle_name).maybe(:string)
      required(:last_name).maybe(:string)
      required(:encrypted_ssn).maybe(:string)
      optional(:name_sfx).maybe(:string)
      required(:gender).maybe(:string)
      required(:aasm_state).maybe(:string)
      required(:dob).filled(:date)
      required(:hired_on).filled(:date)
      required(:benefit_sponsors_employer_profile_id).maybe(Types::Bson)
      required(:benefit_sponsorship_id).maybe(Types::Bson)
      optional(:cobra_begin_date).maybe(:date)
      optional(:employment_terminated_on).maybe(:date)
      optional(:coverage_terminated_on).maybe(:date)
      optional(:employee_role_id).maybe(Types::Bson)
      optional(:employer_profile_id).maybe(Types::Bson)

      optional(:employee_relationship).maybe(:string)
      optional(:employer_assigned_family_id).maybe(:string)
      optional(:expected_selection).maybe(:string)
      optional(:is_business_owner).filled(:bool)
      optional(:no_ssn_allowed).filled(:bool)

      optional(:census_dependents).maybe(:array)
      optional(:address).maybe(:hash)
      optional(:email).maybe(:hash)
    end

    rule(:address) do
      if key? && value
        if value.is_a?(Hash)
          result = Validators::AddressContract.new.call(value)
          key.failure(text: "invalid address", error: result.errors.to_h) if result&.failure?
        else
          key.failure(text: "invalid address. Expected a hash.")
        end
      end
    end

    rule(:email) do
      if key? && value
        if value.is_a?(Hash)
          result = Validators::EmailContract.new.call(value)
          key.failure(text: "invalid email", error: result.errors.to_h) if result&.failure?
        else
          key.failure(text: "invalid email. Expected a hash.")
        end
      end
    end

    rule(:census_dependents).each do
      if key? && value
        if value.is_a?(Hash)
          result = Validators::CensusEmployees::CensusDependentContract.new.call(value)
          key.failure(text: "invalid census_dependent", error: result.errors.to_h) if result&.failure?
        else
          key.failure(text: "invalid census_dependent. Expected a hash.")
        end
      end
    end
  end
end
