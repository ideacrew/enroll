# frozen_string_literal: true

module Entities
  class RidpEligibilityResponse < Dry::Struct

    attribute :primary_member_hbx_id, Types::String.meta(omittable: false)
    attribute :event_kind, Types::RidpEventKinds.meta(omittable: false)

    attribute :ridp_eligibility do
      attribute :delivery_info, Types::Hash.optional.meta(omittable: true)
      attribute :metadata, Types::Hash.optional.meta(omittable: true)
      attribute :event, Types::Hash.optional.meta(omittable: true)
    end

    attribute :created_at, Types::DateTime.optional.meta(omittable: true)
    attribute :deleted_at, Types::DateTime.optional.meta(omittable: true)
  end
end
