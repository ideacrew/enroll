# frozen_string_literal: true

require 'dry/monads'
require 'dry/monads/do'
require 'aca_entities/magi_medicaid/libraries/iap_library'

module FinancialAssistance
  module Operations
    module Applications
      module Pvc
        # operation to manually trigger pvc events.
        # It will take families as input and find the determined application, add evidences and publish the group of applications
        class CreatePvcRequest
          include Dry::Monads[:result, :do]
          include EventSource::Command
          include EventSource::Logging
          include FinancialAssistance::JobsHelper

          def call(params)
            values = yield validate(params)
            family_application = yield fetch_family_application(values[:family_id], values[:manifest][:assistance_year])
            applicant_payload = yield construct_applicant_payload(family_application, values[:person])
            event = yield build_event(values[:manifest], applicant_payload, family_application.hbx_id)
            result = yield publish(event)
            add_evidence(family_application)
            Success(result)
          end

          private

          def fetch_family_application(family_id, year)
            apps = ::FinancialAssistance::Application.where(assistance_year: year,
                                                            aasm_state: 'determined',
                                                            family_id: family_id)

            if apps.present?
              app = apps.max_by(&:created_at)
              Success(app)
            else
              Failure("No applications found for family id #{family_id}")
            end
          end

          def add_evidence(application)
            # apparently there is no different between the rrv or pvc evidences on the way out, they are both non-esi mec
            application.create_rrv_evidences
          end

          def construct_applicant_payload(application, person_params)
            #convert to cv3 and return just the applicant
            person_hbx_id = person_params[:hbx_id]
            cv3_application = FinancialAssistance::Operations::Applications::Transformers::ApplicationTo::Cv3Application.new.call(application)
            return Failure("Cv3Application transform failed for person hbx id: #{person_hbx_id}") unless cv3_application.success?

            applicants = cv3_application.value![:applicants]
            applicant = applicants.detect {|applicant_loop| applicant_loop[:person_hbx_id] == person_hbx_id}
            return Failure("invalid applicant for person hbx id #{person_hbx_id}") unless applicant.present?

            result = AcaEntities::MagiMedicaid::Contracts::ApplicantContract.new.call(applicant)

            if result.success?
              applicant_entity = AcaEntities::MagiMedicaid::Applicant.new(result.to_h)

              Success(applicant_entity)
            else
              Failure(result.errors)
            end
          end

          def validate(params)
            errors = []
            errors << 'person missing' unless params[:person]
            errors << 'manifest missing' unless params[:manifest]
            errors << 'family_id missing' unless params[:family_id]

            errors.empty? ? Success(params) : Failure(errors)
          end

          def build_event(manifest, applicant, application_hbx_id)
            event('events.fdsh.evidences.periodic_verification_confirmation', attributes: { manifest: manifest, applicant: applicant, application_hbx_id: application_hbx_id })
          end

          def publish(event)
            event.publish
            Success("Successfully published the pvc payload")
          end
        end
      end
    end
  end
end