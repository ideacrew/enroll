# frozen_string_literal: true

module Transmittable
  # A process status record for transmittable models
  class ProcessStatus
    include Mongoid::Document
    include Mongoid::Timestamps

    belongs_to :statusable, polymorphic: true, inverse_of: :statusable, index: true
    embeds_many :process_states, class_name: 'Transmittable::ProcessState'
    accepts_nested_attributes_for :process_states

    field :initial_state_key, type: Symbol
    field :latest_state, type: Symbol
    field :elapsed_time, type: Integer

    scope :succeeded, ->(transaction_ids) { where(:latest_state => :succeeded, :statusable_id.in => transaction_ids) }
    scope :not_succeeded, ->(transaction_ids) { where(:latest_state.nin => [:succeeded], :statusable_id.in => transaction_ids) }
  end
end
