# frozen_string_literal: true

require 'dry/monads'
require 'dry/monads/do'

module Operations
  module HbxEnrollments
    #This class finds HBX enrollment object.
    class Find
      include Dry::Monads[:result, :do]

      # @param [ EnrollmentId ] enrollment_id bson_id of a enrollment
      # @return [ Dry::Monads::Result::Success ] enrollment_object
      def call(params)
        enrollment = yield fetch_enrollment(params[:enrollment_id])

        Success(enrollment)
      end

      private

      def fetch_enrollment(enrollment_id)
        enrollment = HbxEnrollment.where(id: enrollment_id).first

        if enrollment
          Success(enrollment)
        else
          Failure({:message => ['Enrollment not found']})
        end
      end
    end
  end
end
