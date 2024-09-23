# frozen_string_literal: true

require 'dry/monads'
require 'dry/monads/do'

module Operations
  module TaxHouseholdGroups
    # this operation is to end current taxhouseholdgroups
    class Deactivate
      include Dry::Monads[:do, :result]
      DEACTIVATE_ACTION_TYPES = ['current_only', 'current_and_prospective'].freeze

      def call(params)
        values = yield validate(params)
        result = yield deactivate(values)

        Success(result)
      end

      private

      def validate(params)
        if params[:family].is_a?(Family) && params[:new_effective_date].is_a?(Date) && DEACTIVATE_ACTION_TYPES.include?(params[:deactivate_action_type])
          Success(params)
        else
          Failure('Invalid params. family should be an instance of Family and new_effective_date should be an instance of Date')
        end
      end

      def deactivate_tax_households(th_group, end_on)
        th_group.tax_households.each do |thh|
          thh.update!(effective_ending_on: end_on)
        end
      end

      def deactivate(values)
        active_thh_groups = values[:family].tax_household_groups.active
        tax_household_groups = case values[:deactivate_action_type]
                               when 'current_only'
                                 active_thh_groups.by_year(values[:new_effective_date].year)
                               when 'current_and_prospective'
                                 active_thh_groups.current_and_prospective_by_year(values[:new_effective_date].year)
                               end
        return Success('No Active Tax Household Groups to deactivate') if tax_household_groups.blank?

        tax_household_groups.each do |th_group|
          new_end_date = values[:new_effective_date] > th_group.start_on ? (values[:new_effective_date] - 1.day) : th_group.start_on
          deactivate_tax_households(th_group, new_end_date)
          th_group.update!(end_on: new_end_date)
        end
        values[:family].save!
        Success("Deactivated all the Active tax_household_groups for given family with hbx_id: #{values[:family].hbx_assigned_id}")
      end
    end
  end
end
