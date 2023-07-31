# frozen_string_literal: true

module Operations
  module Validators
    module Families
      # dummy vlp document contract
      class VlpDocumentContract < Dry::Validation::Contract
        params do
          required(:subject).filled(:string)
          optional(:alien_number).maybe(:string)
          optional(:i94_number).maybe(:string)
          optional(:visa_number).maybe(:string)
          optional(:passport_number).maybe(:string)
          optional(:sevis_id).maybe(:string)
          optional(:naturalization_number).maybe(:string)
          optional(:receipt_number).maybe(:string)
          optional(:citizenship_number).maybe(:string)
          optional(:card_number).maybe(:string)
          optional(:country_of_citizenship).maybe(:string)
          optional(:expiration_date).maybe(:date)
          optional(:issuing_country).maybe(:string)
          optional(:description).maybe(:string)
          optional(:incomes).maybe(:array)
        end
      end
    end
  end
end
