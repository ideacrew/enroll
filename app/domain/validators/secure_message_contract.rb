module Validators
  class SecureMessageContract < ::Dry::Validation::Contract
    params do
      required(:person).hash do
        required(:person_id).filled(:string)
        required(:family_actions_id).filled(:string)
      end
      required(:subject).value(:string)
      required(:body).value(:string)
      optional(:file) # need to have this as required field
    end

    rule(:file) do
      key.failure('Invalid file format') if value.present? && !value.is_a?(ActionDispatch::Http::UploadedFile)
    end

    rule(:subject) do
      key.failure('Please enter subject') if value.blank?
    end

    rule(:body) do
      key.failure('Please enter content') if value.blank?
    end
  end
end