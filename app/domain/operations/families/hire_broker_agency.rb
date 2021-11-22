# frozen_string_literal: true

require 'dry/monads'
require 'dry/monads/do'

module Operations
  module Families
    # Operation to hire broker agency for a given family.
    class HireBrokerAgency
      send(:include, Dry::Monads[:result, :do])

      def call(params)
        valid_params = yield validate(params)
        broker_role = yield find_broker_role(valid_params)
        family = yield find_family(valid_params)
        existing_account = yield find_broker_agency_account(valid_params)
        result = yield hire_broker_agency(existing_account, broker_role, family, valid_params)

        Success(result)
      end

      private

      def validate(params)
        contract_result = Validators::Families::HireBrokerAgencyContract.new.call(params)
        contract_result.success? ? Success(contract_result.to_h) : Failure(contract_result.errors)
      end

      def find_broker_agency_account(params)
        return Success("") if params[:current_broker_account_id].blank?
        ::Operations::Families::BrokerAgencyAccount.new.call({broker_account_id: params[:current_broker_account_id], family_id: params[:family_id]})
      end

      def find_broker_role(valid_params)
        ::Operations::BrokerRole::Find.new.call(valid_params[:broker_role_id])
      end

      def find_family(valid_params)
        ::Operations::Families::Find.new.call(id: valid_params[:family_id])
      end

      def idempotency_check?(existing_account, broker_role, valid_params)
        return false unless existing_account.writing_agent.npn == broker_role.npn
        existing_account.end_on.blank? && valid_params[:terminate_date] <= valid_params[:start_date].to_date
      end

      def terminate_existing_broker_agency(valid_params)
        terminate_params = { family_id: valid_params[:family_id], broker_account_id: valid_params[:current_broker_account_id], terminate_date: valid_params[:terminate_date] }
        ::Operations::Families::TerminateBrokerAgency.new.call(terminate_params)
      end

      def hire_broker_agency(existing_account, broker_role, family, valid_params)
        if existing_account.present?
          same_broker_hire = idempotency_check?(existing_account, broker_role, valid_params)
          return Success(true) if same_broker_hire
          terminate_existing_broker_agency(valid_params)
        end

        family.broker_agency_accounts.new(benefit_sponsors_broker_agency_profile_id: broker_role.benefit_sponsors_broker_agency_profile_id,
                                          writing_agent_id: broker_role.id,
                                          start_on: valid_params[:start_date] || Time.now,
                                          is_active: true)

        family.save! ? Success(true) : Failure("Unable to HireBrokerAgency")
      end
    end
  end
end
