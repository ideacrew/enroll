# frozen_string_literal: true

module Eligible
  module Concerns
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
      end
    end
  end
end
