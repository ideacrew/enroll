# frozen_string_literal: true

module Entities
  # Contains base types and type helpers for type constraints.
  module Types
    include Dry.Types()

    RidpEventKinds = Types::Coercible::String.enum('primary', 'secondary')
  end
end