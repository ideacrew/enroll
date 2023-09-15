# frozen_string_literal: true

module Operations
  module IvlOsseEligibilities
    # Overrides top level eligibility_configuration for ivl osse specific configurations
    class IvlOsseEligibilityConfiguration < ::Operations::Eligible::EligibilityConfiguration
      attr_reader :memoized_eligibilities, :memoized_coverage_periods

      def initialize(effective_date)
        @effective_date = effective_date
        @memoized_eligibilities = {}
        @memoized_coverage_periods = {}

        super()
      end

      def key
        catalog_eligibility&.key || :aca_ivl_osse_eligibility
      end

      def title
        catalog_eligibility&.title || "Aca Ivl Osse Eligibility"
      end

      def benefit_coverage_period
        coverage_period = nil
        calendar_year = @effective_date.year

        if defined?(memoized_coverage_periods) &&
             memoized_coverage_periods.key?(calendar_year)
          return memoized_coverage_periods[calendar_year]
        end

        memoized_coverage_periods[calendar_year] = HbxProfile
          &.current_hbx
          &.benefit_sponsorship
          &.benefit_coverage_periods
          &.by_date(@effective_date)
          &.first
      end

      def catalog_eligibility
        return unless benefit_coverage_period
        calendar_year = benefit_coverage_period.start_on.year

        if defined?(memoized_eligibilities) &&
             memoized_eligibilities.key?(calendar_year)
          return memoized_eligibilities[calendar_year]
        end

        memoized_eligibilities[calendar_year] = benefit_coverage_period
          .eligibilities
          .by_key("aca_ivl_osse_eligibility_#{calendar_year}")
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
