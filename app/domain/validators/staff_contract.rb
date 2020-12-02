# frozen_string_literal: true

module Validators
  class StaffContract < Dry::Validation::Contract

    params do
      required(:first_name).filled(:string)
      required(:last_name).filled(:string)
      optional(:dob).filled(:date)
      optional(:area_code).filled(:string)
      optional(:number).filled(:string)
      optional(:email).filled(:string)
      # toDo - Add is appyling coverage attributes by adding new contract
    end
  end
end
