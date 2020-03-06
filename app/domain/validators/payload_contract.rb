module Validators
  class PayloadContract < ::Dry::Validation::Contract
    params do
      required(:url).value(:string)

      required(:payload).hash do
        required(:authorized_subjects).array(:hash) do
          required(:id).value(:string)
          required(:type).value(:string)
        end

        required(:authorized_identity).hash do
          required(:user_id).value(:string)
          required(:system).value(:string)
        end
        required(:path).value(:string)
        required(:document_type).value(:string)
      end

      required(:headers).hash do
        optional(:content_type).value(:string)
      end
    end
  end
end