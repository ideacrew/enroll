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
        family = yield find_family(valid_params)
        result = yield terminate_broker_agency(agency_account, valid_params)
        notify_broker_terminated_event_to_edi(valid_params, family)
        Success(result)
      end

      private

      def validate(params)
        contract_result = Validators::Families::TerminateBrokerAgencyContract.new.call(params)
        contract_result.success? ? Success(contract_result.to_h) : Failure(contract_result.errors)
      end

      def find_broker_agency_account(params)
        ::Operations::Families::FindBrokerAgencyAccount.new.call(params)
      end

      def terminate_broker_agency(account, params)
        result = account.update_attributes!(end_on: (params[:terminate_date].to_date - 1.day).end_of_day, is_active: false)
        result ? Success(true) : Failure("Unable to TerminateBrokerAgency")
      end

      def find_family(valid_params)
        ::Operations::Families::Find.new.call(id: valid_params[:family_id])
      end

      def notify_broker_terminated_event_to_edi(valid_params, family)
        return Success("") unless valid_params[:notify_edi]
        return Success("") unless broker_role&.npn&.scan(/\D/)&.empty?

        family.notify_broker_update_on_impacted_enrollments_to_edi({family_id: family.id.to_s})
      end
    end
  end
end
