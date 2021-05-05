# frozen_string_literal: true

module Operations
  module CensusEmployees
    # This class initializes a census_employee entity after
    # validating the incoming census_employee params.
    class Build
      include Dry::Monads[:result, :do]

      # @param [ Hash ] census_employee attributes
      # @return [ ::Entities::CensusEmployees::CensusEmployee ] census_employee
      def call(params)
        values = yield validate(params)
        entity = yield initialize_entity(values)

        Success(entity)
      end

      private

      def validate(params)
        contract_result = ::Validators::CensusEmployees::CensusEmployeeContract.new.call(params)
        contract_result.success? ? Success(contract_result.to_h) : Failure(contract_result.errors)
      end

      def initialize_entity(values)
        Success(::Entities::CensusEmployees::CensusEmployee.new(values.to_h))
      end
    end
  end
end
