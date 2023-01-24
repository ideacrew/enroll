# frozen_string_literal: true

module Validators
  module BenchmarkProducts
    # Schema and validation rules for {Entities::BenchmarkProducts::BenchmarkProduct}
    class BenchmarkProductContract < ::Dry::Validation::Contract

      params do
        optional(:family_id).maybe(Types::Bson)
        required(:effective_date).filled(:date)
        optional(:primary_rating_address_id).maybe(Types::Bson)
        optional(:rating_area_id).maybe(Types::Bson)
        optional(:exchange_provided_code).maybe(:string)
        optional(:service_area_ids).array(Types::Bson)
        optional(:household_group_benchmark_ehb_premium).maybe(::AcaEntities::Types::Money)

        optional(:rating_address).hash do
          required(:county).filled(:string)
          required(:zip).filled(:string)
          required(:state).filled(included_in?: State::NAME_IDS.map(&:last))
        end

        required(:households).array(:hash) do
          required(:household_id).filled(:string)
          optional(:type_of_household).maybe(Types::BenchmarkProductsHouseholdType)
          optional(:household_benchmark_ehb_premium).maybe(::AcaEntities::Types::Money)
          optional(:health_product_hios_id).maybe(Types::String)
          optional(:health_product_title).maybe(Types::String)
          optional(:health_product_csr_variant_id).maybe(Types::String)
          optional(:health_product_id).maybe(Types::Bson)
          optional(:health_ehb).maybe(::AcaEntities::Types::Money)
          optional(:household_health_benchmark_ehb_premium).maybe(::AcaEntities::Types::Money)
          optional(:health_product_covers_pediatric_dental_costs).maybe(:bool)
          optional(:dental_product_hios_id).maybe(Types::String)
          optional(:dental_product_title).maybe(Types::String)
          optional(:dental_product_id).maybe(Types::Bson)
          optional(:dental_rating_method).maybe(Types::String)
          optional(:dental_ehb_apportionment_for_pediatric_dental).maybe(::AcaEntities::Types::Money)
          optional(:household_dental_benchmark_ehb_premium).maybe(::AcaEntities::Types::Money)
          required(:members).array(:hash) do
            optional(:family_member_id).maybe(Types::Bson)
            required(:relationship_with_primary).filled(:string, included_in?: ::PersonRelationship::Kinds)
            optional(:date_of_birth).maybe(:date)
            optional(:age_on_effective_date).maybe(:integer)
            optional(:coverage_start_on).maybe(:date)
          end
        end
      end

      # We need family_id (or)
      #   we need :date_of_birth of all members for each Household, &
      #   we need county, zip, state based on EnrollRegistry[:enroll_app].settings(:rating_areas).item('single', 'county', 'zipcode')
      rule(:family_id) do
        unless keys.include?(:family_id) && value
          if values[:households].present?
            values[:households].each_with_index do |household, hh_index|
              next unless household[:members].any? { |mmbr| mmbr[:date_of_birth].nil? }

              key(
                [:households, hh_index, :members, :date_of_birth]
              ).failure(text: 'please provide date of births of all household members')
            end
          end

          key(:rating_address).failure(text: 'please provide rating address') if values[:rating_address].blank?
        end
      end
    end
  end
end
