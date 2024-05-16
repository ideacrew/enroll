# frozen_string_literal: true

require 'dry/monads'
require 'dry/monads/do'

module FinancialAssistance
  module Operations
    module EnrollmentDates
      class EarliestEffectiveDate
        include Dry::Monads[:do, :result]

        # @param [ Date ] application_date Application Created Date
        # @return [ Date ] earliest_effective_date Application Earliest Effective Date
        def call(application_date: TimeKeeper.date_of_record, assistance_year: TimeKeeper.date_of_record.year)
          earliest_effective_date = yield calculate(application_date, assistance_year)

          Success(earliest_effective_date)
        end

        private

        def calculate(application_date, assistance_year)
          override_enabled = FinancialAssistanceRegistry.feature_enabled?(:faa_fifteenth_of_the_month_rule_overridden)
          effective_date = if application_date.mday <= FinancialAssistanceRegistry[:enrollment_dates].setting(:enrollment_due_day_of_month).item || override_enabled
            application_date.end_of_month + 1.day
          else
            application_date.next_month.end_of_month + 1.day
          end

          start_on = Date.new(assistance_year, 1, 1)

          effective_date = [[effective_date, start_on].max, start_on.end_of_year].min

          Success(effective_date)
        end

      end
    end
  end
end
