# frozen_string_literal: true

module Validators
  module PremiumCredits
    # This class checks and validates the incoming params
    # that are required to build a new MemberPremiumCredit object,
    # if any of the checks or rules fail it returns a Failure Monad
    class MemberContract < Dry::Validation::Contract

      params do
        required(:kind).filled(included_in?: ::MemberPremiumCredit::KINDS)
        required(:value).filled(:string)
        required(:start_on).filled(:date)
        optional(:end_on).maybe(:date)
        required(:family_member_id).filled(Types::Bson)
      end

      rule(:value) do
        if key? && value
          key.failure("must be one of: #{MemberPremiumCredit::CSR_VALUES} for kind: csr") if values[:kind] == 'csr' && !MemberPremiumCredit::CSR_VALUES.include?(value)

          key.failure("must be one of: #{MemberPremiumCredit::APTC_VALUES} for kind: aptc_eligible") if values[:kind] == 'aptc_eligible' && !MemberPremiumCredit::APTC_VALUES.include?(value)
        end
      end
    end
  end
end