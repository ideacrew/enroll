# frozen_string_literal: true

module Fdsh
  module Ridp
    class EligibilityResponseModel
      include Mongoid::Document
      include Mongoid::Timestamps

      field :primary_member_hbx_id, type: String
      field :event_kind, type: String
      field :ridp_eligibility, type: Hash
      field :deleted_at, type: DateTime

    end
  end
end
