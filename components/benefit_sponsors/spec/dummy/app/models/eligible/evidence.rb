# frozen_string_literal: true

module Eligible
  # Evidence model
  class Evidence
    include Mongoid::Document
    include Mongoid::Timestamps

    STATUSES = %i[initial approved denied].freeze
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

    scope :by_key, ->(key) { where(key: key.to_sym) }

    def latest_state_history
      state_histories.latest_history
    end

    def is_eligible_on?(date)
      eligible_periods.any? do |period|
        if period[:end_on].present?
          (period[:start_on]..period[:end_on]).cover?(date)
        else
          (period[:start_on]..period[:start_on].end_of_year).cover?(date)
        end
      end
    end

    def eligible_periods
      eligible_periods = []
      date_range = {}
      state_histories.non_initial.each do |state_history|
        date_range[:start_on] ||= state_history.effective_on if state_history.to_state == :approved

        next unless date_range.present? && state_history.to_state == :denied
        date_range[:end_on] = state_history.effective_on.prev_day
        eligible_periods << date_range
        date_range = {}
      end

      eligible_periods << date_range unless date_range.empty?
      eligible_periods
    end
  end
end
