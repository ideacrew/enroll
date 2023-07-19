# frozen_string_literal: true

module Eligible
  module Concerns
    # Concern for Eligibility
    module Eligibility
      extend ActiveSupport::Concern

      included do
        include AASM
        include Recordable

        ELIGIBLE_STATES = %i[eligible].freeze
        INELIGIBLE_STATES = %i[draft ineligible].freeze

        field :title, type: String
        field :description, type: String
        field :current_state, type: Symbol

        embeds_many :state_histories,
                    class_name: '::Eligible::StateHistory',
                    cascade_callbacks: true,
                    as: :status_trackable

        validates_presence_of :title

        delegate :effective_on,
                 :is_eligible,
                 to: :latest_state_history,
                 allow_nil: false

        aasm column: :current_state do
          state :draft, initial: true
          state :eligible
          state :ineligible

          event :move_to_eligible, :after => [:record_transition] do
            transitions from: :draft, to: :eligible
            transitions from: :ineligible, to: :eligible
          end

          event :move_to_ineligible, :after => [:record_transition] do
            transitions from: :draft, to: :ineligible
            transitions from: :eligible, to: :ineligible
          end
        end

        def latest_state_history
          state_histories.latest_history
        end
      end
    end
  end
end
