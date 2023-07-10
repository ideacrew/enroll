# frozen_string_literal: true

module Eligible
  module Concerns
    module Evidence
      extend ActiveSupport::Concern

      included do
        field :title, type: String
        field :description, type: String
        field :key, type: Symbol
        field :is_satisfied, type: Boolean

        embeds_many :state_histories,
                    class_name: '::Eligible::StateHistory',
                    cascade_callbacks: true,
                    as: :status_trackable

        validates_presence_of :title, :key, :is_satisfied
      end
    end
  end
end
