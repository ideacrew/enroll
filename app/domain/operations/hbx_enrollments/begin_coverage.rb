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

      def begin_coverage(enrollment)
        return Failure("Failed to begin coverage for enrollment hbx id #{enrollment.hbx_id} - #{enrollment.kind} is not a valid IVL enrollment kind") unless enrollment.is_ivl_by_kind?
        enrollment.begin_coverage!

        Success("Successfully began coverage for enrollment hbx id #{enrollment.hbx_id}")
      rescue StandardError => e
        Failure("Failed to begin coverage for enrollment hbx id #{enrollment.hbx_id} - #{e.message}")
      end
    end
  end
end
