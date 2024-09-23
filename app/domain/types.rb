# frozen_string_literal: true

require 'cgi'
require 'dry-types'

Dry::Types.load_extensions(:maybe)

module Types
  include Dry.Types
  include Dry::Logic

  REASONS = QualifyingLifeEventKind.non_draft.map(&:reason).uniq
  QLEKREASONS = Types::Coercible::String.enum(*REASONS)

  RidpEventKinds = Types::Coercible::String.enum('primary', 'secondary')

  # Benchmark Products Household Type
  BenchmarkProductsHouseholdType = Types::Coercible::String.enum('adult_only', 'adult_and_child', 'child_only')
end
