# frozen_string_literal: true

module Eligibilities
  # A fact - usually obtained from an external service - that contributes to determining
  # whether a subject is eligible to make use of a benefit resource
  class EvidenceSource
    include Mongoid::Document
    include Mongoid::Timestamps

    field :key, type: Symbol
    field :title, type: String
    field :description, type: String
    field :value, type: String

    embedded_in :evidence, class_name: 'Eligibilities::Evidence'
    embeds_one :event, class_name: 'EventSource::Event'

    validates_presence_of :key
  end
end
