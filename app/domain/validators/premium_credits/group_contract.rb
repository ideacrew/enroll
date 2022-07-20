# frozen_string_literal: true

module Validators
  module PremiumCredits
    # This class checks and validates the incoming params
    # that are required to build a new GroupPremiumCredit object,
    # if any of the checks or rules fail it returns a Failure Monad
    class GroupContract < Dry::Validation::Contract

      params do
        required(:kind).filled(included_in?: ::GroupPremiumCredit::KINDS)
        optional(:authority_determination_id).maybe(Types::Bson)
        optional(:authority_determination_class).maybe(:string)
        optional(:premium_credit_monthly_cap).maybe(:float)
        optional(:sub_group_id).maybe(Types::Bson)
        optional(:sub_group_class).maybe(:string)
        optional(:expected_contribution_percentage).maybe(:float)
        required(:start_on).filled(:date)
        optional(:end_on).maybe(:date)

        required(:member_premium_credits).filled(:array)
      end

      rule(:member_premium_credits) do
        if key? && value
          validated_member_pcs = []
          value.each_with_index do |member_pc, index|
            if member_pc.is_a?(Hash)
              result = Validators::PremiumCredits::MemberContract.new.call(member_pc)
              if result&.failure?
                key([:member_premium_credits, index]).failure(text: 'invalid member_premium_credit', error: result.errors.to_h)
              else
                validated_member_pcs << result.to_h
              end
            else
              key([:member_premium_credits, index]).failure(text: 'invalid member_premium_credit. Expected a hash.')
            end
          end
          values.merge!(member_premium_credits: validated_member_pcs)
        end
      end
    end
  end
end