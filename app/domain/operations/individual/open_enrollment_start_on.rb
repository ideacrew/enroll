# frozen_string_literal: true

require 'dry/monads'
require 'dry/monads/do'

module Operations
  module Individual
    # Fetches open enrollment start on benefit coverage period based on the provided date
    class OpenEnrollmentStartOn
      include Dry::Monads[:do, :result]

      def call(params)
        effective_date = yield validate_date(params[:date])
        result = yield fetch_bcp_by_effective_period(effective_date)

        Success(result)
      end

      private

      def validate_date(date)
        return Failure("Given input is not in date format") unless date.is_a?(Date)

        Success(date)
      end

      def fetch_bcp_by_effective_period(date)
        bcp = HbxProfile.bcp_by_effective_period(date)
        return Failure("Could not find benefit coverage period effective for give date") unless bcp.present?
        oe_start_on = bcp.open_enrollment_start_on
        return Failure("Benefit coverage period for the given date does not have open enrollment start on") unless oe_start_on.present?

        Success(oe_start_on)
      end
    end
  end
end
