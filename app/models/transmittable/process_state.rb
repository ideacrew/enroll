# frozen_string_literal: true

module Transmittable
  # A process state for transmittable models
  class ProcessState
    include Mongoid::Document
    include Mongoid::Timestamps

    embedded_in :process_status, class_name: 'Transmittable::ProcessStatus'

    field :event, type: String
    field :message, type: String
    field :state_key, type: Symbol
    field :started_at, type: DateTime
    field :ended_at, type: DateTime
    field :seconds_in_state, type: Integer
  end
end