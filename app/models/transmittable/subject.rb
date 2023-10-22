# frozen_string_literal: true

module Transmittable
  # A data model for a unitary transaction
  module Subject
    extend ActiveSupport::Concern

    included do
      has_many :transactions, as: :transactable, class_name: '::Transmittable::Transaction'
    end
  end
end
