# frozen_string_literal: true

require 'dry/monads'
require 'dry/monads/do'

module Operations
  module PremiumCredits
    # This operation is to build Group Premium Credit.
    class Build
      include Dry::Monads[:result, :do]

      def call(params)
        values = yield validate(params)
        result = yield create(values)

        Success(result)
      end

      private

      def validate(params)
        result = ::Validators::PremiumCredits::GroupContract.new.call(params[:gpc_params])

        if result.success?
          Success(result.to_h)
        else
          Failure(result)
        end
      end

      def create(values)
        group_premium_credit = ::GroupPremiumCredit.new(values.except(:member_premium_credits))
        values[:member_premium_credits].map do |member_params|
          group_premium_credit.member_premium_credits.build(member_params)
        end

        if group_premium_credit.valid?
          Success(group_premium_credit)
        else
          Failure(group_premium_credit.errors.full_messages)
        end
      end
    end
  end
end
