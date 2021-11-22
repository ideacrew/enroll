# frozen_string_literal: true

module Validators
  module Families
    # Validator that validates broker agency hire params.
    class HireBrokerAgencyContract < Dry::Validation::Contract

      params do
        required(:family_id).filled(Types::Bson)
        optional(:current_broker_account_id).maybe(Types::Bson)
        required(:broker_role_id).filled(Types::Bson)
        optional(:terminate_date).maybe(:date)
        required(:start_date).maybe(:date_time)
      end

      rule(:broker_role_id) do
        if key? && value
          result = ::Operations::BrokerRole::Find.new.call(values[:broker_role_id])
          key.failure(text: 'invalid broker_role_id', error: result.failure) if result&.failure?
          key.failure(text: 'missing benefit_sponsors_broker_agency_profile_id in broker role', error: result) if result&.success&.benefit_sponsors_broker_agency_profile_id.blank?
        end
      end

      rule(:current_broker_account_id) do
        if key? && values[:current_broker_account_id].present?
          result = ::Operations::Families::FindBrokerAgencyAccount.new.call({family_id: values[:family_id], broker_account_id: values[:current_broker_account_id]})
          key.failure(text: 'invalid broker_account_id', error: result.failure) if result&.failure?
        end
      end
    end
  end
end
