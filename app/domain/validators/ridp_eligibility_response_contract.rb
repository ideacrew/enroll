# frozen_string_literal: true

module Validators
  # Ridp eligibility response validator
  class RidpEligibilityResponseContract < ::Dry::Validation::Contract
    params do
      required(:primary_member_hbx_id).filled(:string)
      optional(:event_kind).maybe(Types::RidpEventKinds)

      optional(:ridp_eligibility).schema do
        optional(:delivery_info).maybe(:string)
        optional(:metadata).maybe(:string)
        optional(:event).maybe(:hash)
      end

      optional(:created_at).maybe(:date_time)
      optional(:deleted_at).maybe(:date_time)
    end
  end
end
