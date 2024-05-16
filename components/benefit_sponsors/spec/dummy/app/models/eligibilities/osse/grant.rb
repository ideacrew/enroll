# frozen_string_literal: true

module Eligibilities
  module Osse
    # Grant model
    class Grant
      include Mongoid::Document
      include Mongoid::Timestamps

      # embedded_in :evidenceable, polymorphic: true
      embedded_in :eligibility, class_name: "::Eligibilities::Osse::Eligibility"

      field :title, type: String
      field :description, type: String
      field :key, type: Symbol
      field :start_on, type: Date
      field :end_on, type: Date

      embeds_one :value, class_name: "::Eligibilities::Osse::Value", cascade_callbacks: true

      accepts_nested_attributes_for :value

      validates_presence_of :key, :start_on, :value

    end
  end
end
