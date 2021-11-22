# frozen_string_literal: true

require 'dry/monads'
require 'dry/monads/do'

module Operations
  module Families
    # Operation to terminate broker agency for a given family.
    class TerminateBrokerAgency
      send(:include, Dry::Monads[:result, :do])

      def call(params)
        valid_params = yield validate(params)
        agency_account = yield find_broker_agency_account(valid_params)
        result = yield terminate_broker_agency(agency_account, valid_params)

        Success(result)
      end

      private

      def validate(params)
        contract_result = Validators::Families::TerminateBrokerAgencyContract.new.call(params)
        contract_result.success? ? Success(contract_result.to_h) : Failure(contract_result.errors)
      end

      def find_broker_agency_account(params)
        ::Operations::Families::BrokerAgencyAccount.new.call(params)
      end

      def terminate_broker_agency(account, params)
        result = account.update_attributes!(end_on: (params[:terminate_date].to_date - 1.day).end_of_day, is_active: false)
        result ? Success(true) : Failure("Unable to TerminateBrokerAgency")
      end
    end
  end
end
