# frozen_string_literal: true

require 'dry/monads'
require 'dry/monads/do'

module Operations
  module PremiumCredits
    # This operation is to find Group Premium Credit.
    class FindAll
      include Dry::Monads[:do, :result]

      def call(params)
        values = yield validate(params)
        result = yield find_all(values)

        Success(result)
      end

      private

      def validate(params)
        return Failure('Invalid params. family should be an instance of Family') unless params[:family].is_a?(Family)
        return Failure('Missing year') unless params[:year]
        return Failure('Missing kind') unless params[:kind]

        Success(params)
      end

      def find_all(values)
        grants = values[:family].eligibility_determination&.grants&.where(key: values[:kind], assistance_year: values[:year])

        Success(grants)
      end
    end
  end
end
