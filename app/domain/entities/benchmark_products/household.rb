# frozen_string_literal: true

module Entities
  module BenchmarkProducts
    class Household < Dry::Struct

      attribute :type_of_household, Types::BenchmarkProductsHouseholdType.optional.meta(omittable: true)
      attribute :household_benchmark_ehb_premium, ::AcaEntities::Types::Money.optional.meta(omittable: true)
      attribute :health_product_hios_id, Types::String.optional.meta(omittable: true)
      attribute :health_product_id, Types::Bson.optional.meta(omittable: true)
      attribute :health_ehb, ::AcaEntities::Types::Money.optional.meta(omittable: true)
      attribute :household_health_benchmark_ehb_premium, ::AcaEntities::Types::Money.optional.meta(omittable: true)
      attribute :health_product_covers_pediatric_dental_costs, Types::Bool.optional.meta(omittable: true)
      attribute :dental_product_hios_id, Types::String.optional.meta(omittable: true)
      attribute :dental_product_id, Types::Bson.optional.meta(omittable: true)
      attribute :dental_rating_method, Types::String.optional.meta(omittable: true)
      attribute :dental_ehb, ::AcaEntities::Types::Money.optional.meta(omittable: true)
      attribute :household_dental_benchmark_ehb_premium, ::AcaEntities::Types::Money.optional.meta(omittable: true)
      attribute :members, Types::Array.of(Entities::BenchmarkProducts::Member).meta(omittable: false)
    end
  end
end
