module Validators
  class ResultContract < ::Dry::Validation::Contract
    params do
      required(:status).value(:string)
      optional(:reference_id).value(:string)
      optional(:errors).maybe(:string)
    end

    rule(:status) do
      key.failure('Invalid status') unless value != "success" || value != "faailure"
    end

    rule(:errors) do
      binding.pry
      key.failure('Invalid errors') unless value == 'null'
    end
  end
end