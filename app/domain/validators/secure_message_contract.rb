module Validators
  class SecureMessageContract < ::Dry::Validation::Contract
    params do
      optional(:person_id)
      optional(:profile_id)
      required(:actions_id).filled(:string)
      required(:subject).value(:string)
      required(:body).value(:string)
      optional(:file) # need to have this as required field
    end

    rule(:file) do
      key.failure('Invalid file format') if value.present? && value == 'undefined' && !value.is_a?(ActionDispatch::Http::UploadedFile)
    end

    rule(:subject) do
      key.failure('Please enter subject') if value.blank?
    end

    rule(:body) do
      key.failure('Please enter content') if value.blank?
    end
  end
end