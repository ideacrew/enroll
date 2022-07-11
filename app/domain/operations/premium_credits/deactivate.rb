# frozen_string_literal: true

require 'dry/monads'
require 'dry/monads/do'

module Operations
  module PremiumCredits
    # This operation is to deactivate Group Premium Credits.
    class Deactivate
      include Dry::Monads[:result, :do]

      # Input Params Example: { family: Family.new, new_effective_date: Date.new }
      def call(params)
        values = yield validate(params)
        result = yield deactivate(values)

        Success(result)
      end

      private

      def validate(params)
        if params[:family]&.is_a?(Family) && params[:new_effective_date]&.is_a?(Date)
          Success(params)
        else
          Failure('Invalid params. family should be an instance of Family and new_effective_date should be an instance of Date')
        end
      end

      # Should not fail for cases with no active Group Premium Credits
      # returns Success('message')
      def deactivate(values)
        group_premium_credits = values[:family].group_premium_credits.active.by_year(values[:new_effective_date].year).aptc_csr
        return Success('No Active Group Premium Credits to deactivate') if group_premium_credits.blank?

        group_premium_credits.each { |gpc| gpc.end_on = (values[:new_effective_date] > gpc.start_on) ? values[:date] : gpc.start_on }
        values[:family].save!
        Success("Deactivated all the Active aptc_csr Group Premium Credits for given family with hbx_id: #{values[:family].hbx_assigned_id}")
      end
    end
  end
end
