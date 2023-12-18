# frozen_string_literal: true

module Transmittable
  # This is the join table that will be connecting both transmission and transaction.
  # This object is created at the enqueue process to connect a transaction to a transmission.
  class TransactionsTransmissions
    include Mongoid::Document
    include Mongoid::Timestamps

    belongs_to :transmission, class_name: 'Transmittable::Transmission', index: true
    belongs_to :transaction, class_name: 'Transmittable::Transaction', index: true
  end
end
