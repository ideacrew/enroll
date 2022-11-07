# frozen_string_literal: true

require 'dry/monads'
require 'dry/monads/do'

module Operations
  module TaxHouseholdGroups
    # this operation is to create eligibility
    class CreateEligibility
      send(:include, Dry::Monads[:result, :do])

      def call(params)
        values = yield validate(params)
        yield deactivate(values)
        yield create_taxhousehold_group(values[:th_group_info])
        yield create_family_determination
        yield create_new_enrollments

        Success()
      end

      private

      def validate(params)
        return Failure('Invalid params. family should be an instance of family') unless params[:family].is_a?(Family)
        return Failure('Missing th_group_info') unless params[:th_group_info]

        Success(params)
      end

      def deactivate(values)
        @family = values[:family]
        @effective_date = Date.strptime(values[:th_group_info][:effective_date], '%m/%d/%Y')

        ::Operations::TaxHouseholdGroups::Deactivate.new.call({ family: @family, new_effective_date: @effective_date })
      end

      def create_taxhousehold_group(th_group_info)
        ::Operations::TaxHouseholdGroups::Create.new.call({ family: @family, th_group_info: th_group_info })
      end

      def create_family_determination
        ::Operations::Eligibilities::BuildFamilyDetermination.new.call(family: @family.reload, effective_date: @effective_date)
      end

      def create_new_enrollments
        return Success() unless EnrollRegistry.feature_enabled?(:apply_aggregate_to_enrollment)

        ::Operations::Individual::OnNewDetermination.new.call({family: @family.reload, year: @effective_date.year})
      end
    end
  end
end
