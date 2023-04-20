# frozen_string_literal: true

module Eligibilities
  module Osse
    # Evidence model
    class Evidence
      include Mongoid::Document
      include Mongoid::Timestamps

      EVIDENCE_KEYS = %i[
        osse_subsidy
      ].freeze

      embedded_in :eligibility, class_name: '::Eligibilities::Osse::Eligibility'

      field :title, type: String
      field :description, type: String
      field :key, type: Symbol
      field :is_satisfied, type: Boolean
      field :updated_by, type: String

      scope :by_key, ->(key) { where(key: key) }
    end
  end
end
