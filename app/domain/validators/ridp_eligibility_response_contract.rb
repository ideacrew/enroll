# frozen_string_literal: true

module Validators
  # Ridp eligibility response validator
  class RidpEligibilityResponseContract < ::Dry::Validation::Contract
    params do
      required(:primary_member_hbx_id).filled(:string)
      required(:event_kind).maybe(Types::RidpEventKinds)

      optional(:ridp_eligibility).schema do
        optional(:delivery_info).maybe(:hash)
        optional(:metadata).maybe(:hash)
        optional(:event).maybe(:hash)
      end

      optional(:created_at).maybe(:date_time)
      optional(:deleted_at).maybe(:date_time)
    end
  end
end
