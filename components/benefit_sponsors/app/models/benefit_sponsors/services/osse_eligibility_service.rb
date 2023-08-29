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

      # Needed to display valid osse eligible application period date ranges in multi year interface
      def osse_status_by_year
        osse_eligibility_years_for_display.each_with_object({}) do |year, data|
          data[year] = {}
          effective_on = effective_on_for_year(year.to_i)
          eligibility = benefit_sponsorship.active_eligibility_on(effective_on)
          if eligibility
            data[year][:is_eligible] = true
          else
            data[year][:is_eligible] = false
          end
          application = benefit_sponsorship.benefit_applications.by_year(year).approved_and_terminated.select(&:osse_eligible?).last
          next unless application

          data[year][:start_on] = application.start_on.to_date
          data[year][:end_on] = application.end_on.to_date
        end
      end

      # rubocop:disable Metrics/CyclomaticComplexity
      def update_osse_eligibilities_by_year
        eligibility_result = {}

        args[:osse].each do |year, osse_eligibility|
          effective_on = effective_on_for_year(year.to_i)
          active_eligibility = benefit_sponsorship.active_eligibility_on(effective_on)
          current_eligibility_status = active_eligibility.present?

          next if current_eligibility_status.to_s == osse_eligibility

          effective_on = active_eligibility.effective_on if osse_eligibility == "false" # FIXME
          eligibility_result[year] = store_osse_eligibility(osse_eligibility, effective_on)
        end

        grouped_eligibilities = eligibility_result.group_by { |_year, value| value }
        grouped_eligibilities.transform_values { |items| items.map(&:first) }
      end
      # rubocop:enable Metrics/CyclomaticComplexity

      def store_osse_eligibility(osse_eligibility, effective_on)
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

      def effective_on_for_year(year)
        calendar_year = TimeKeeper.date_of_record.year
        start_on = Date.new(year, 1, 1)
        start_on = TimeKeeper.date_of_record if year == calendar_year
        start_on = start_on.end_of_year if year < calendar_year
        start_on
      end
    end
  end
end
