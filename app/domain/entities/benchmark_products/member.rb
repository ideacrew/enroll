# frozen_string_literal: true

module Entities
  module BenchmarkProducts
    class Member < Dry::Struct

      attribute :family_member_id, Types::Bson.meta(omittable: false)
      attribute :relationship_with_primary, Types::String.meta(omittable: false)
      attribute :date_of_birth, Types::Date.optional.meta(omittable: true)
      attribute :age_on_effective_date, Types::Integer.optional.meta(omittable: true)
      attribute :coverage_start_on, Types::Date.optional.meta(omittable: true)
    end
  end
end
