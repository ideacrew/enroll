# frozen_string_literal: true

module Operations
  module CensusEmployees
    # This class clones a census employee and returns census employee object.
    class Clone
      include Dry::Monads[:result, :do]

      # @param [ CensusEmployee ] census_employee
      # @return [ CensusEmployee ] census_employee
      def call(params)
        values         = yield validate(params)
        census_attrs   = yield construct_params(values)
        census_record  = yield build_census_employee(census_attrs)
        new_ce         = yield clone_census_employee(census_record)

        Success(new_ce)
      end

      private

      def validate(params)
        return Failure('Missing CensusEmployee.') unless params.key?(:census_employee)
        return Failure('Not a valid CensusEmployee object.') unless params[:census_employee].is_a?(::CensusEmployee)
        return Failure("Invalid options's value. Should be a Hash.") unless params[:additional_attrs].is_a?(Hash)

        Success(params)
      end

      def construct_params(values)
        params = values[:census_employee].serializable_hash.deep_symbolize_keys.except(:_id, :created_at, :updated_at, :benefit_sponsors_employer_profile_id, :employer_profile_id, :benefit_sponsorship_id)
        params.merge!(values[:additional_attrs])
        Success(params)
      end

      def build_census_employee(census_attrs)
        Operations::CensusEmployees::Build.new.call(census_attrs)
      end

      def clone_census_employee(census_record)
        census_employee = ::CensusEmployee.new(census_record.to_h)
        Success(census_employee)
      end
    end
  end
end
