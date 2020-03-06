# frozen_string_literal: true

module Validators
  class DocumentUploadContract < ::Dry::Validation::Contract
    params do
      required(:subject).value(:string)
      required(:file) # need to have this as required field
      optional(:content_type).value(:string)
    end

    rule(:file) do
      key.failure('Invalid file format') unless value.is_a? ActionDispatch::Http::UploadedFile
    end
  end
end