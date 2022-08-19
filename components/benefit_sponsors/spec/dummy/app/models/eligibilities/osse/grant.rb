# frozen_string_literal: true

module Eligibilities
  module Osse
    # Grant model
    class Grant
      include Mongoid::Document
      include Mongoid::Timestamps
      # include ::EventSource::Command
      # include Dry::Monads[:result, :do, :try]
      # include GlobalID::Identification
      # include Eligibilities::Eventable

      # DUE_DATE_STATES = %w[review outstanding rejected].freeze

      # embedded_in :evidenceable, polymorphic: true
      embedded_in :eligibility, class_name: "::Eligibilities::Osse::Eligibility"

      field :title, type: String
      field :description, type: String
      field :key, type: Symbol
      field :start_on, type: Date
      field :end_on, type: Date
      field :value, type: String
      # field :updated_by, type: String
      # field :update_reason, type: String

      embeds_one :value, class_name: "::Eligibilities::Osse::Value", cascade_callbacks: true

      accepts_nested_attributes_for :value

      validates_presence_of :key, :start_on, :value

    end
  end
end
