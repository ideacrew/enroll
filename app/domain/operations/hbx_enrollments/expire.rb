# frozen_string_literal: true

module Operations
  module HbxEnrollments
    # Expire IVL enrollment coverage
    class Expire
      include Dry::Monads[:result, :do]

      # @param [Hash] params
      # @option params [String] :enrollment_hbx_id
      # @return [Dry::Monads::Result]
      def call(params)
        enrollment_hbx_id = yield validate(params)
        hbx_enrollment    = yield find_enrollment(enrollment_hbx_id)
        _valid_expiration = yield validate_expiration(hbx_enrollment)
        result            = yield expire_enrollment(hbx_enrollment)

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

      def validate_expiration(enrollment)
        failures = []
        failures << "#{enrollment.kind} is not a valid IVL enrollment kind" unless enrollment.market_name == 'Individual'
        failures << "enrollment does not meet the expiration criteria" unless enrollment.may_expire_coverage?
        if failures.empty?
          Success(enrollment)
        else
          Failure("Unable to expire enrollment hbx id #{enrollment.hbx_id} - #{failures.join(', ')}")
        end
      end

      def expire_enrollment(enrollment)
        result = enrollment.expire_coverage!
        return Failure("Failed to expire enrollment hbx id #{enrollment.hbx_id}.") unless result

        Success("Successfully expired enrollment hbx id #{enrollment.hbx_id}")
      end
    end
  end
end
