# frozen_string_literal: true

module Services
  # service for ivl osse actions
  class IvlOsseEligibilityService

    attr_reader :person, :role, :args

    def initialize(params)
      @person = Person.find(params[:person_id])
      @role = fetch_role
      @args = params
    end

    def fetch_role
      if person.has_active_resident_role?
        person.resident_role
      elsif person.has_active_consumer_role?
        person.consumer_role
      end
    end

    def osse_eligibility_years_for_display
      ::BenefitCoveragePeriod.osse_eligibility_years_for_display.sort.reverse
    end

    # rubocop:disable Metrics/CyclomaticComplexity
    def osse_status_by_year
      osse_eligibility_years_for_display.inject({}) do |data, year|
        data[year] = {}
        effective_on = effective_on_for_year(year.to_i)
        eligibility = get_eligibility_by_date(effective_on)
        data[year][:is_eligible] = eligibility&.is_eligible_on?(effective_on) || false
        next data unless eligibility.present?

        latest_eligibility_period = eligibility.evidences.last&.eligible_periods&.last
        next data unless latest_eligibility_period.present?

        data[year][:start_on] = latest_eligibility_period[:start_on]
        data[year][:end_on] = latest_eligibility_period[:end_on] || latest_eligibility_period[:start_on].end_of_year

        data
      end
    end

    def update_osse_eligibilities_by_year
      eligibility_result = {}

      args[:osse].each do |year, osse_eligibility|
        current_year = TimeKeeper.date_of_record.year
        if year.to_i < (current_year - 1)
          eligibility_result[year] = "Failure"
          next
        end
        effective_on = effective_on_for_year(year.to_i)
        eligibility = get_eligibility_by_date(effective_on)

        current_eligibility_status = eligibility&.is_eligible_on?(effective_on)&.to_s || 'false'
        next if current_eligibility_status == osse_eligibility.to_s

        effective_on = get_eligibility_end_date(year.to_i, eligibility) if eligibility&.is_eligible_on?(effective_on) && (osse_eligibility.to_s == 'false')

        result = store_osse_eligibility(role, osse_eligibility, effective_on)
        eligibility_result[year] = result.success? ? "Success" : "Failure"
      end

      eligibility_result.group_by { |_key, value| value }.transform_values { |items| items.map(&:first) }
    end
    # rubocop:enable Metrics/CyclomaticComplexity

    def store_osse_eligibility(role, osse_eligibility, effective_on)
      effective_on = effective_on.beginning_of_year if EnrollRegistry.feature_enabled?("aca_ivl_osse_effective_beginning_of_year") && osse_eligibility.to_s == "true"
      ::Operations::IvlOsseEligibilities::CreateIvlOsseEligibility.new.call(
        {
          subject: role.to_global_id,
          evidence_key: :ivl_osse_evidence,
          evidence_value: osse_eligibility.to_s,
          effective_date: effective_on
        }
      )
    end

    def get_eligibility_end_date(year, eligibility)
      calendar_year = TimeKeeper.date_of_record.year
      end_on = eligibility.effective_on
      end_on = TimeKeeper.date_of_record if year == calendar_year
      end_on
    end

    def effective_on_for_year(year)
      calendar_year = TimeKeeper.date_of_record.year
      start_on = Date.new(year, 1, 1)
      start_on = TimeKeeper.date_of_record if year == calendar_year
      start_on = start_on.end_of_year if year < calendar_year
      start_on
    end

    def get_eligibility_by_date(start_on)
      role.eligibility_on(start_on)
    end
  end
end
