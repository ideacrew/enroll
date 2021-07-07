# frozen_string_literal: true

module Entities
  class RidpEligibilityResponse < Dry::Struct
    attribute :primary_member_hbx_id, Types::String.meta(omittable: true)
    attribute :event_kind, Types::RidpEventKinds.meta(omittable: true)
    attribute :ridp_eligibility do
      attribute :delivery_info, Types::String.optional
      attribute :metadata, Types::String.optional
      attribute :event, Types::String.optional
    end
    attribute :created_at, Types::DateTime.meta(omittable: true)
    attribute :deleted_at, Types::DateTime.optional
  end
end
