# frozen_string_literal: true

require 'dry/monads'
require 'dry/monads/do'

module Operations
  module HbxEnrollments
    # find enrollment
    class Find
      include Dry::Monads[:do, :result]

      def call(query_hash)
        q_hash = yield validate(query_hash)
        enrollment = yield find_hbx_enrollment(q_hash)

        Success(enrollment)
      end

      private

      def validate(query_hash)
        result = Validators::HbxEnrollments::FindContract.new.call(query_hash)

        if result.success?
          Success(result.to_h)
        else
          Failure(result.errors.to_h)
        end
      end

      def find_hbx_enrollment(q_hash)
        hbx = HbxEnrollment.where(q_hash).first
        if hbx.present?
          Success(hbx)
        else
          Failure('Enrollment not found')
        end
      rescue StandardError
        Failure("Unable to find HbxEnrollment for #{q_hash}.")
      end
    end
  end
end
