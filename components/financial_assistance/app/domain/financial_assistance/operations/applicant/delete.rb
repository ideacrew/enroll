# frozen_string_literal: true

require 'dry/monads'
require 'dry/monads/do'

module FinancialAssistance
  module Operations
    module Applicant
      class Delete
        send(:include, Dry::Monads[:result, :do])
        send(:include, Dry::Monads[:try])

        def call(financial_applicant: , family_id: )
          values        = yield validate(financial_applicant)
          @application  = yield find_draft_application(family_id)
          applicant     = yield match_applicant(values, @application)
          result        = yield delete_applicant(applicant)

          Success(result)
        end

        private

        def validate(params)
          result = ::FinancialAssistance::Validators::ApplicantContract.new.call(params)

          if result.success?
            Success(result.to_h)
          else
            Failure(result)
          end
        end

        def find_draft_application(family_id)
          application =  ::FinancialAssistance::Application.where(family_id: family_id, aasm_state: 'draft').first
          if application
            Success(application)
          else
            Failure("Application Not Found")
          end
        end

        def match_applicant(financial_applicant, application)
          result = application.applicants.where(person_hbx_id: financial_applicant[:person_hbx_id]).first
          result.present? ? Success(result) : Failure('Unable to find applicant.')
        end

        def delete_applicant(applicant)
          Try {
            applicant_id = applicant
            applicant&.destroy!
            @application.relationships.where(applicant_id: applicant_id).destroy_all
            @application.relationships.where(relative_id: applicant_id).destroy_all
          }
        end
      end
    end
  end
end
