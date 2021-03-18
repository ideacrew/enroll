# frozen_string_literal: true

module Operations
  module CensusEmployees
    # This class copies roster to the new ER account
    class CopyRoster
      include Dry::Monads[:result, :do]

      # @param [ Profile ] profile
      # @return [ CensusEmployee ] census_employees
      def call(params)
        values           = yield validate(params)
        profile          = yield find_profile(values[:existing_profile_id])
        _census_records  = yield clone_census_records(profile, values[:new_profile_id], values[:new_benefit_sponsorship_id])

        Success()
      end

      private

      def validate(params)
        return Failure('Missing Existing Profile') if params[:existing_profile_id].blank?
        return Failure('Missing New Profile') if params[:new_profile_id].blank?
        return Failure('Missing New BenefitSponsorship') if params[:new_benefit_sponsorship_id].blank?
        Success(params)
      end

      def find_profile(id)
        Success(::BenefitSponsors::Organizations::Profile.find(id))
      end

      def clone_census_records(profile, benefit_sponsors_employer_profile_id, new_benefit_sponsorship_id)
        census_records = profile.census_employees

        clone_operation = ::Operations::CensusEmployees::Clone.new
        census_records.each do |census_record|
          result = clone_operation.call({census_employee: census_record, additional_attrs: { benefit_sponsors_employer_profile_id: benefit_sponsors_employer_profile_id, benefit_sponsorship_id: new_benefit_sponsorship_id }})
          if result.success?
            result.value!.save
          else
            Rails.logger.error { "Unable to clone census_employee - #{result.failure.errors}" }
          end
        end

        Success({})
      end
    end
  end
end
