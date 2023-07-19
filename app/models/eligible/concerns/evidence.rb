# frozen_string_literal: true

module Eligible
  module Concerns
    # Concern for Evidence
    module Evidence
      extend ActiveSupport::Concern

      included do
        include AASM
        include Recordable

        ELIGIBLE_STATES = %w[attested pending review outstanding verified].freeze
        INELIGIBLE_STATES = %w[initialized unverified negative_response_received].freeze

        field :title, type: String
        field :description, type: String
        field :key, type: Symbol
        field :is_satisfied, type: Boolean, default: false
        field :current_state, type: String

        embeds_many :state_histories,
                    class_name: '::Eligible::StateHistory',
                    cascade_callbacks: true,
                    as: :status_trackable

        validates_presence_of :title, :key, :is_satisfied

        delegate :effective_on,
                 :is_eligible,
                 to: :latest_state_history,
                 allow_nil: false

        aasm column: :current_state do
          state :initialized, initial: true
          state :attested
          state :pending
          state :review
          state :outstanding
          state :verified
          state :unverified
          state :negative_response_received

          event :attest, :after => [:record_transition] do
            transitions from: :initialized, to: :attested
            transitions from: :pending, to: :attested
            transitions from: :attested, to: :attested
            transitions from: :review, to: :attested
            transitions from: :outstanding, to: :attested
            transitions from: :rejected, to: :attested
            transitions from: :unverified, to: :attested
            transitions from: :negative_response_received, to: :attested
            transitions from: :attested, to: :attested
          end

          event :negative_response_received, :after => [:record_transition] do
            transitions from: :pending, to: :negative_response_received
            transitions from: :attested, to: :negative_response_received
            transitions from: :verified, to: :negative_response_received
            transitions from: :review, to: :negative_response_received
            transitions from: :outstanding, to: :negative_response_received
            transitions from: :rejected, to: :negative_response_received
            transitions from: :unverified, to: :negative_response_received
            transitions from: :negative_response_received, to: :negative_response_received
          end

          event :move_to_unverified, :after => [:record_transition] do
            transitions from: :pending, to: :unverified
            transitions from: :attested, to: :unverified
            transitions from: :review, to: :unverified
            transitions from: :outstanding, to: :unverified
            transitions from: :verified, to: :unverified
            transitions from: :unverified, to: :unverified
            transitions from: :rejected, to: :unverified
            transitions from: :negative_response_received, to: :unverified
          end

          event :move_to_outstanding, :after => [:record_transition] do
            transitions from: :pending, to: :outstanding
            transitions from: :negative_response_received, to: :outstanding
            transitions from: :outstanding, to: :outstanding
            transitions from: :review, to: :outstanding
            transitions from: :attested, to: :outstanding
            transitions from: :verified, to: :outstanding
            transitions from: :unverified, to: :outstanding
            transitions from: :rejected, to: :outstanding
          end

          event :move_to_verified, :after => [:record_transition] do
            transitions from: :pending, to: :verified
            transitions from: :verified, to: :verified
            transitions from: :review, to: :verified
            transitions from: :attested, to: :verified
            transitions from: :outstanding, to: :verified
            transitions from: :unverified, to: :verified
            transitions from: :negative_response_received, to: :verified
            transitions from: :rejected, to: :verified
          end

          event :move_to_review, :after => [:record_transition] do
            transitions from: :pending, to: :review
            transitions from: :negative_response_received, to: :review
            transitions from: :review, to: :review
            transitions from: :outstanding, to: :review
            transitions from: :attested, to: :review
            transitions from: :verified, to: :review
            transitions from: :rejected, to: :review
            transitions from: :unverified, to: :review
          end

          event :move_to_pending, :after => [:record_transition] do
            transitions from: :attested, to: :pending
            transitions from: :pending, to: :pending
            transitions from: :review, to: :pending
            transitions from: :outstanding, to: :pending
            transitions from: :verified, to: :pending
            transitions from: :rejected, to: :pending
            transitions from: :unverified, to: :pending
            transitions from: :negative_response_received, to: :pending
          end
        end

        def latest_state_history
          state_histories.latest_history
        end
      end
    end
  end
end
