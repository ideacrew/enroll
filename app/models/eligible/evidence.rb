# frozen_string_literal: true

module Eligible
  # Evidence model
  class Evidence
    include Mongoid::Document
    include Mongoid::Timestamps

    embedded_in :eligibility, class_name: "::Eligible::Eligibility"

    STATUSES = %i[initial not_approved approved denied].freeze
    ELIGIBLE_STATUSES = %i[approved].freeze

    field :key, type: Symbol
    field :title, type: String
    field :description, type: String
    field :is_satisfied, type: Boolean, default: false
    field :current_state, type: Symbol, default: :initial
    field :subject_ref, type: String
    field :evidence_ref, type: String

    embeds_many :state_histories,
                class_name: "::Eligible::StateHistory",
                cascade_callbacks: true,
                as: :status_trackable

    validates_presence_of :title, :key, :is_satisfied

    delegate :effective_on,
             :is_eligible,
             to: :latest_state_history,
             allow_nil: false

    delegate :eligible?,
             :is_eligible_on?,
             :eligible_periods,
             to: :decorated_eligible_record,
             allow_nil: true

    scope :by_key, ->(key) { where(key: key.to_sym) }

    def latest_state_history
      state_histories.last
    end

    def active_state
      :approved
    end

    def inactive_state
      :denied
    end

    def eligible?
      current_state == active_state
    end

    def decorated_eligible_record
      EligiblePeriodHandler.new(self)
    end
  end
end
