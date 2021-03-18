# frozen_string_literal: true

module Validators::CensusEmployees
  class CensusDependentContract < Dry::Validation::Contract

    params do
      required(:first_name).maybe(:string)
      optional(:middle_name).maybe(:string)
      required(:last_name).maybe(:string)
      required(:encrypted_ssn).maybe(:string)
      optional(:name_sfx).maybe(:string)
      required(:gender).maybe(:string)
      required(:dob).filled(:date)
      required(:employee_relationship).maybe(:string)
      optional(:employer_assigned_family_id).maybe(:string)
    end
  end
end
