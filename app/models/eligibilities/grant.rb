# frozen_string_literal: true

module Eligibilities
  class Grant
    include Mongoid::Document
    include Mongoid::Timestamps

    KEYS = ['aptc_grant', 'csr_grant'].freeze

    field :title, type: String
    field :key, type: String
    field :value, type: Float
    field :start_on, type: Date
    field :end_on, type: Date
    field :year, type: Integer
    field :member_ids, type: Array

    embedded_in :determination, class_name: "::Eligibilities::Determination"
    embedded_in :eligibility_state, class_name: "::Eligibilities::EligibilityState"

  end
end