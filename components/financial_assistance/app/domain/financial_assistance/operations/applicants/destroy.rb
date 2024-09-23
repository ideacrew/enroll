# frozen_string_literal: true

require 'dry/monads'
require 'dry/monads/do'

module FinancialAssistance
  module Operations
    module Applicants
      # This Operation is for destroying/deleting an Applicant.
      class Destroy
        include Dry::Monads[:do, :result]

        # @param [::FinancialAssistance::Applicant] opts The options to destroy Applicant
        # @option opts [::FinancialAssistance::Applicant]
        # @return [Dry::Monads::Result]
        def call(applicant)
          applicant = yield validate(applicant)
          result    = yield destroy_applicant(applicant)

          Success(result)
        end

        private

        def validate(applicant)
          return Failure("Given input: #{applicant} is not a valid FinancialAssistance::Applicant.") unless applicant.is_a?(::FinancialAssistance::Applicant)
          return Failure("Given applicant with person_hbx_id: #{applicant.person_hbx_id} is a primary applicant, cannot be destroyed/deleted.") if applicant.is_primary_applicant
          @application = applicant.application
          return Failure("The application with hbx_id: #{@application.hbx_id} for given applicant with person_hbx_id: #{applicant.person_hbx_id} is not a draft application, applicant cannot be destroyed/deleted.") unless @application.draft?

          Success(applicant)
        end

        def destroy_applicant(applicant)
          person_hbx_id = applicant.person_hbx_id
          @application.relationships.where(applicant_id: applicant.id).destroy_all
          @application.relationships.where(relative_id: applicant.id).destroy_all
          applicant.destroy!

          Success("Successfully destroyed applicant with person_hbx_id: #{person_hbx_id}.")
        end
      end
    end
  end
end
