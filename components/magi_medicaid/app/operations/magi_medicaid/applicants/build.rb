# frozen_string_literal: true

require 'dry/monads'
require 'dry/monads/do'

module MagiMedicaid
  module Applicants
    # Operations to build applicants in magi medicaid.
    class Build
      send(:include, Dry::Monads[:result, :do])

      # @param [ Hash ] params Applicant Attributes
      # @return [FinancialAssistance::Entities::Applicant ] applicant Applicant
      def call(params:)
        values     = yield validate(params)
        applicant  = yield build(values)

        Success(applicant)
      end

      private

      def validate(params)
        result = ::MagiMedicaid::ApplicantContract.new.call(params)

        if result.success?
          Success(result.to_h)
        else
          Failure(result)
        end
      end

      def build(values)
        applicant_entity = ::MagiMedicaid::ApplicantEntity.new(values)

        Success(applicant_entity)
      end
    end
  end
end