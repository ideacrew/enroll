# frozen_string_literal: true

module Entities
  module BenchmarkProducts
    class RatingAddress < Dry::Struct
      attribute :county, Types::String.meta(omittable: false)
      attribute :zip, Types::String.meta(omittable: false)
      attribute :state, Types::String.meta(omittable: false)
    end
  end
end
