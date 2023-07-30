# frozen_string_literal: true

module Eligible
  # Evidence model
  class Evidence
    include Mongoid::Document
    include Mongoid::Timestamps

    STATUSES = %i[initial approved denied].freeze

    field :key, type: Symbol
    field :title, type: String
    field :description, type: String
    field :is_satisfied, type: Boolean, default: false
    field :current_state, type: Symbol
    field :subject_ref, type: String
    field :evidence_ref, type: String

    embeds_many :state_histories,
                class_name: '::Eligible::StateHistory',
                cascade_callbacks: true,
                as: :status_trackable

    validates_presence_of :title, :key, :is_satisfied

    delegate :effective_on,
             :is_eligible,
             to: :latest_state_history,
             allow_nil: false

    scope :by_key, ->(key) { where(key: key.to_sym) }

    def latest_state_history
      state_histories.latest_history
    end
  end
end
