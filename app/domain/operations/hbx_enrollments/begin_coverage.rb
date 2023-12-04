# frozen_string_literal: true

module Operations
  module HbxEnrollments
    # Begin IVL enrollment coverage
    class BeginCoverage
      include Dry::Monads[:result, :do]

      # @param [Hash] params
      # @option params [String] :enrollment_hbx_id
      # @return [Dry::Monads::Result]
      def call(params)
        enrollment_hbx_id = yield validate(params)
        hbx_enrollment    = yield find_enrollment(enrollment_hbx_id)
        _valid_expiration = yield validate_coverage(hbx_enrollment)
        result            = yield begin_coverage(hbx_enrollment)

        Success(result)
      end

      private

      def validate(params)
        return Failure('Missing enrollment_hbx_id') unless params.key?(:enrollment_hbx_id)

        Success(params[:enrollment_hbx_id])
      end

      def find_enrollment(enrollment_hbx_id)
        Operations::HbxEnrollments::Find.new.call({hbx_id: enrollment_hbx_id})
      end

      def validate_coverage(enrollment)
        failures = []
        failures << "#{enrollment.kind} is not a valid IVL enrollment kind" unless enrollment.market_name == 'Individual'
        failures << "enrollment does not meet the coverage initiation criteria" unless enrollment.may_begin_coverage?
        if failures.empty?
          Success(enrollment)
        else
          Failure("Unable to begin coverage for enrollment hbx id #{enrollment.hbx_id} - #{failures.join(', ')}")
        end
      end

      def begin_coverage(enrollment)
        result = enrollment.begin_coverage!
        return Failure("Failed to begin coverage for enrollment hbx id #{enrollment.hbx_id}.") unless result

        Success("Successfully began coverage for enrollment hbx id #{enrollment.hbx_id}")
      end
    end
  end
end
