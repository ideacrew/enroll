# frozen_string_literal: true

module Eligibilities
  # Use Visitor Development Pattern to access Eligibilities and Eveidences
  # distributed across models
  class EvidenceItem
    include Mongoid::Document
    include Mongoid::Timestamps

    embedded_in :eligibility_item

    field :key, type: Symbol
    field :title, type: String
    field :description, type: String
    field :subject_ref, type: String
    field :evidence_ref, type: String
  end
end
