# frozen_string_literal: true

module Eligible
  # Grant model
  class Grant
    include Mongoid::Document
    include Mongoid::Timestamps

    embedded_in :eligibility, class_name: "::Eligible::Eligibility"

    field :key, type: Symbol
    field :title, type: String
    field :description, type: String

    embeds_one :value, class_name: "::Eligible::Value", cascade_callbacks: true

    validates_presence_of :title, :key

    scope :by_key, ->(key) { where(key: key.to_sym) }
  end
end
