# frozen_string_literal: true

module Transmittable
  # Persistence model for all transmissions
  class Transmission
    include Mongoid::Document
    include Mongoid::Timestamps

    belongs_to :job, class_name: 'Transmittable::Job', optional: true
    has_many :transactions_transmissions, class_name: 'Transmittable::TransactionsTransmissions'
    has_one :process_status, as: :statusable, class_name: 'Transmittable::ProcessStatus'
    accepts_nested_attributes_for :process_status
    has_many :transmittable_errors, as: :errorable, class_name: 'Transmittable::Error'
    accepts_nested_attributes_for :transmittable_errors

    field :key, type: Symbol
    field :title, type: String
    field :description, type: String
    field :started_at, type: DateTime, default: -> { Time.now }
    field :ended_at, type: DateTime
    field :transmission_id, type: String

    # Indexes
    index({ created_at: 1 })

    def error_messages
      return [] unless errors

      transmittable_errors&.map {|error| "#{error.key}: #{error.message}"}&.join(";")
    end
  end
end
