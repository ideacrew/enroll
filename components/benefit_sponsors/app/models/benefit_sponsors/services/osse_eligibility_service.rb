# frozen_string_literal: true

module BenefitSponsors
  module Services
    #service for osse eligibility actions
    class OsseEligibilityService

      attr_reader :employer_profile, :args, :benefit_sponsorship

      def initialize(employer_profile, args = {})
        @employer_profile = employer_profile
        @benefit_sponsorship = employer_profile.active_benefit_sponsorship
        @args = args
      end

      def osse_eligibility_years_for_display
        ::BenefitMarkets::BenefitMarketCatalog.osse_eligibility_years_for_display.sort.reverse
      end

      def osse_status_by_year
        osse_eligibility_years_for_display.inject({}) do |data, year|
          data[year] = {}
          start_on = Date.new(year, 0o1, 0o1)

          eligibility = benefit_sponsorship.eligibility_for("aca_shop_osse_eligibility_#{year}".to_sym, start_on)
          eligible_on = year == TimeKeeper.date_of_record.year ? TimeKeeper.date_of_record : start_on
          data[year][:is_eligible] = eligibility&.is_eligible_on?(eligible_on) || false
          next data unless eligibility.present?
          latest_eligibility_period = eligibility.evidences.first&.eligible_periods&.last
          data[year][:start_on] = latest_eligibility_period[:start_on]
          data[year][:end_on] = latest_eligibility_period[:end_on] || latest_eligibility_period[:start_on].end_of_year

          data
        end
      end

      def get_osse_term_date(published_on)
        if published_on.year == TimeKeeper.date_of_record.year
          TimeKeeper.date_of_record
        else
          published_on
        end
      end

      def update_osse_eligibilities_by_year
        eligibility_result = {}
        args[:osse].each do |year, osse_eligibility|
          effective_on = Date.new(year.to_i, 0o1, 0o1)
          eligibility_record = benefit_sponsorship.eligibility_for("aca_shop_osse_eligibility_#{year}".to_sym, effective_on)
          eligible_on = (year.to_i == TimeKeeper.date_of_record.year) ? TimeKeeper.date_of_record : effective_on
          if eligibility_record&.is_eligible_on?(eligible_on) && osse_eligibility.to_s == 'false'
            term_date = get_osse_term_date(eligibility_record.published_on)
            eligibility_result[year] = create_or_term_osse_eligibility(benefit_sponsorship, osse_eligibility, term_date)
          elsif osse_eligibility.to_s == 'true'
            eligibility_result[year] = create_or_term_osse_eligibility(benefit_sponsorship, osse_eligibility, effective_on)
          end
        end
        eligibility_result.group_by { |_key, value| value }.transform_values { |items| items.map(&:first) }
      end

      def create_or_term_osse_eligibility(benefit_sponsorship, osse_eligibility, effective_on)
        result = ::BenefitSponsors::Operations::BenefitSponsorships::ShopOsseEligibilities::CreateShopOsseEligibility.new.call(
          {
            subject: benefit_sponsorship.to_global_id,
            evidence_key: :shop_osse_evidence,
            evidence_value: osse_eligibility.to_s,
            effective_date: effective_on
          }
        )
        result.success? ? "Success" : "Failure"
      end
    end
  end
end