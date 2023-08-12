# frozen_string_literal: true

module Operations
  module IvlOsseEligibilities
    # Overrides top level eligibility_configuration for ivl osse specific configurations
    class OsseEligibilityConfiguration < ::Operations::Eligible::EligibilityConfiguration
      def initialize(effective_date)
        @effective_date = effective_date
        super()
      end

      def key
        catalog_eligibility&.key || :aca_ivl_osse_eligibility
      end

      def title
        catalog_eligibility&.title || "Aca Ivl Osse Eligibility"
      end

      def benefit_coverage_period
        HbxProfile
          &.current_hbx
          &.benefit_sponsorship
          &.benefit_coverage_periods
          &.by_date(@effective_date)
          &.first
      end

      def catalog_eligibility
        return unless benefit_coverage_period
        benefit_coverage_period
          .eligibilities
          .by_key(
            "aca_ivl_osse_eligibility_#{benefit_coverage_period.start_on.year}"
          )
          .first
      end

      def grants
        return [] unless catalog_eligibility

        catalog_eligibility.grants.collect do |grant|
          [grant.key, grant.value.item]
        end
      end
    end
  end
end
