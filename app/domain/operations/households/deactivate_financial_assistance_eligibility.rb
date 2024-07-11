# frozen_string_literal: true

require 'dry/monads'
require 'dry/monads/do'

module Operations
  module Households
    class DeactivateFinancialAssistanceEligibility
      include Dry::Monads[:do, :result]

      #params: {family_id , date}
      def call(params:)
        values = yield validate(params)
        result = yield execute(values)

        Success(result)
      end

      private

      def validate(params)
        if params[:family_id]&.is_a?(BSON::ObjectId) && params[:date].present?
          Success(params)
        else
          Failure('family_id is expected in BSON format and date in required')
        end
      end

      # should not fail for UQHP cases too
      # returns Success(nil)
      def execute(values)
        family = Operations::Families::Find.new.call(id: BSON::ObjectId(values[:family_id]))
        return family if family.failure?
        tax_households = family.success.active_household.latest_active_tax_households
        active_tax_households = case values[:deactivate_action_type]
                                when 'current_and_prospective'
                                  tax_households.current_and_prospective_by_year(values[:date].to_date.year)
                                when 'current_only'
                                  tax_households.tax_household_with_year(values[:date].to_date.year)
                                end
        return Success('No Active Tax Households to deactivate') unless active_tax_households.present?

        active_tax_households.each do |thh|
          end_on = (values[:date] > thh.effective_starting_on) ? values[:date] : thh.effective_starting_on
          thh.update_attributes!(effective_ending_on: end_on)
        end

        Success("End dated all the Active Tax Households for given family with bson_id: #{values[:family_id]}")
      end
    end
  end
end
