# frozen_string_literal: true

require 'dry/monads'
require 'dry/monads/do'

module Operations
  module Families
    # Operation to find broker agency account for a given family
    class FindBrokerAgencyAccount
      include Dry::Monads[:do, :result]

      def call(params)
        valid_params = yield validate(params)
        broker_agency_account = yield find_broker_agency_account(valid_params)

        Success(broker_agency_account)
      end

      private

      def validate(params)
        if params[:family_id].is_a?(BSON::ObjectId) && params[:broker_account_id].is_a?(BSON::ObjectId)
          Success(params)
        else
          Failure('Invalid params for BrokerAgencyAccount')
        end
      end

      def find_broker_agency_account(valid_params)
        result = ::Operations::Families::Find.new.call(id: valid_params[:family_id])
        return Failure("Unable to find BrokerAgencyAccount with ID #{valid_params[:broker_account_id]} for Family #{valid_params[:family_id]}.") unless result&.success?

        account = result.success.broker_agency_accounts.unscoped.find(valid_params[:broker_account_id])
        account.present? ? Success(account) : Failure("Unable to find BrokerAgencyAccount with ID #{valid_params[:broker_account_id]} for Family #{valid_params[:family_id]}.")
      rescue StandardError
        Failure("Unable to find BrokerAgencyAccount with ID #{valid_params[:broker_account_id]} for Family #{valid_params[:family_id]}.")
      end
    end
  end
end
