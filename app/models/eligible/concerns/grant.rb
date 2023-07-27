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
        field :current_state, type: Symbol

        embeds_one :value,
                   class_name: '::Eligible::Value',
                   cascade_callbacks: true

        validates_presence_of :title, :key

      end
    end
  end
end
