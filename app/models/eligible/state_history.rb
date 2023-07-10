# frozen_string_literal: true

module Eligibile
  # State history model
  class StateHistory
    include Mongoid::Document
    include Mongoid::Timestamps

    embedded_in :status_trackable, polymorphic: true

    field :effective_on, type: Date
    field :is_eligible, type: Boolean

    field :from_state, type: String
    field :to_state, type: String
    field :transition_at, type: DateTime

    field :event, type: String
    field :comment, type: String
    field :reason, type: String

    validates_presence_of :effective_on,
                          :is_eligible,
                          :from_state,
                          :to_state,
                          :transition_at
  end
end
