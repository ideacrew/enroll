# frozen_string_literal: true

module BenefitSponsors
  module Entities
    class EnrollmentEligibility < Dry::Struct
      transform_keys(&:to_sym)

      attribute :market_kind,                     Types::Strict::Symbol
      attribute :benefit_sponsorship_id,          Types::Bson
      attribute :effective_date,                  Types::Strict::Date
      attribute :benefit_application_kind,        Types::Strict::Symbol
      attribute :service_areas,                   Types::Array.of(BenefitMarkets::Entities::ServiceArea)
      attribute :osse_min_employer_contribution,  Types::Strict::Bool
      attribute :sponsor_eligibilities,           Types::Array.optional.meta(omittable: true)

      def metal_level_products_restricted?
        sponsor_eligibilities.any?{|e| e.grant_for(:employer_metal_level_products).present?}
      end

      def employer_contribution_minimum_relaxed?
        sponsor_eligibilities.any?{|e| e.grant_for(:all_contribution_levels_min_met).present?}
      end
    end
  end
end
