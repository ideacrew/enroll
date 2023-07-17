# frozen_string_literal: true

module Eligible
  module Concerns
    # Concern for Grant
    module Grant
      extend ActiveSupport::Concern

      included do
        field :title, type: String
        field :description, type: String
        field :key, type: Symbol

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
                 :current_state,
                 to: :latest_state_history,
                 allow_nil: false

        def latest_state_history
          state_histories.latest_history
        end
      end
    end
  end
end
