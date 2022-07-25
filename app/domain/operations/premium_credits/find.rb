# frozen_string_literal: true

require 'dry/monads'
require 'dry/monads/do'

module Operations
  module PremiumCredits
    # This operation is to find Group Premium Credit.
    class Find
      include Dry::Monads[:result, :do]

      def call(params)
        values = yield validate(params)
        result = yield find(values)

        Success(result)
      end

      private

      def validate(params)
        return Failure('Invalid params. family should be an instance of Family') unless params[:family].is_a?(Family)
        return Failure('Missing year') unless params[:year]
        return Failure('Missing kind') unless params[:kind]

        Success(params)
      end

      def find(values)
        active_group_premium_credits = values[:family].group_premium_credits.where(kind: values[:kind]).active
        group_premium_credit = active_group_premium_credits.by_year(values[:year]).order_by(:created_at.desc).first

        Success(group_premium_credit)
      end
    end
  end
end
