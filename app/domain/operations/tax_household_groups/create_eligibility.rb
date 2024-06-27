# frozen_string_literal: true

require 'dry/monads'
require 'dry/monads/do'

module Operations
  module TaxHouseholdGroups
    # Creates a new financial assistance eligibility for a family.
    #
    # This operation is specifically used by the Hbx Admin to establish a new eligibility instance for a family.
    # It is applicable only under the Tax Model 2.0 and when the feature `:temporary_configuration_enable_multi_tax_household_feature` is enabled.
    # The process involves deactivating the current eligibility, if any, and then creating a new one.
    #
    # @note This operation is only applicable for Tax Model 2.0 when the feature `:temporary_configuration_enable_multi_tax_household_feature` is enabled.
    class CreateEligibility
      include Dry::Monads[:do, :result]
      include L10nHelper

      def call(params)
        values = yield validate(params)
        yield deactivate(values)
        yield create_taxhousehold_group(values[:th_group_info])
        yield create_family_determination
        yield create_new_enrollments

        Success(l10n('create_eligibility_tool.success_message'))
      end

      private

      def validate(params)
        return Failure('Invalid params. family should be an instance of family') unless params[:family].is_a?(Family)
        return Failure('Missing th_group_info') unless params[:th_group_info]
        return Failure(l10n('create_eligibility_tool.no_members_applying_coverage')) if params[:family].none_applying_coverage?

        Success(params)
      end

      def deactivate(values)
        @family = values[:family]
        @effective_date = Date.strptime(values[:th_group_info][:effective_date], '%m/%d/%Y')

        ::Operations::TaxHouseholdGroups::Deactivate.new.call(
          {
            deactivate_action_type: 'current_only',
            family: @family,
            new_effective_date: @effective_date
          }
        )
      end

      def create_taxhousehold_group(th_group_info)
        ::Operations::TaxHouseholdGroups::Create.new.call({ family: @family, th_group_info: th_group_info })
      end

      def create_family_determination
        ::Operations::Eligibilities::BuildFamilyDetermination.new.call(family: @family.reload, effective_date: @effective_date)
      end

      def create_new_enrollments
        return Success() unless EnrollRegistry.feature_enabled?(:apply_aggregate_to_enrollment)

        ::Operations::Individual::OnNewDetermination.new.call({ family: @family.reload, year: @effective_date.year })
        Success()
      end
    end
  end
end
