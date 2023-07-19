# frozen_string_literal: true

module Eligible
  module Concerns
    # Concern for Grant
    module Grant
      extend ActiveSupport::Concern

      included do
        include AASM
        include Recordable

        ELIGIBLE_STATES = %w[active].freeze
        INELIGIBLE_STATES = %w[draft expired].freeze

        field :title, type: String
        field :description, type: String
        field :key, type: Symbol
        field :current_state, type: String

        embeds_one :value,
                   class_name: '::Eligible::Value',
                   cascade_callbacks: true

        embeds_many :state_histories,
                    class_name: '::Eligible::StateHistory',
                    cascade_callbacks: true,
                    as: :status_trackable

        validates_presence_of :title, :key

        delegate :effective_on,
                 :is_eligible,
                 to: :latest_state_history,
                 allow_nil: false

        aasm column: :current_state do
          state :draft, initial: true
          state :active
          state :expired

          event :move_to_active, :after => [:record_transition] do
            transitions from: :draft, to: :active
            transitions from: :expired, to: :active
          end

          event :move_to_expired, :after => [:record_transition] do
            transitions from: :draft, to: :expired
            transitions from: :active, to: :expired
          end
        end

        def latest_state_history
          state_histories.latest_history
        end
      end
    end
  end
end
