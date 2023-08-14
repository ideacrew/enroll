# frozen_string_literal: true

module Eligible
  # State history model
  class StateHistory
    include Mongoid::Document
    include Mongoid::Timestamps

    embedded_in :status_trackable, polymorphic: true

    field :effective_on, type: Date
    field :is_eligible, type: Boolean, default: false

    field :from_state, type: Symbol
    field :to_state, type: Symbol
    field :transition_at, type: DateTime

    field :event, type: Symbol
    field :comment, type: String
    field :reason, type: String

    validates_presence_of :effective_on,
                          :is_eligible,
                          :from_state,
                          :to_state,
                          :transition_at

    scope :by_state, ->(state) { where(to_state: state.to_sym) }
    scope :non_initial, -> { where(:to_state.ne => :initial) }

    def self.latest_history
      order(transition_at: :desc).first
    end
  end
end