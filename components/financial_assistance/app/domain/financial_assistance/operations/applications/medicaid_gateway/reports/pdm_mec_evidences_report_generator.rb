# frozen_string_literal: true

# Operation::Applications::MedicaidGateway::Reports::PdmMecEvidencesReportGenerator.new.call({ year: 2023 })
module Operations
  module Applications
    module MedicaidGateway
      module Reports
        # This class is responsible for generating a report of MEC evidences for applicants
        class PdmMecEvidencesReportGenerator
          include Dry::Monads[:do, :result, :try]

          def call(params)
            year = yield validate(params)
            families = yield enrolled_and_renewing_families
            application_hbx_ids = yield latest_determined_applications(families, year)
            evidences_hash = yield fetch_mec_evidences(application_hbx_ids)
            generate_report(evidences_hash)
          end

          private

          def validate(params)
            year = params[:year]
            return Failure('year is missing') unless year.present?

            Success(year)
          end

          def enrolled_and_renewing_families
            Operations::Families::FetchEnrolledAndRenewingAssisted.new.call({})
          end

          def latest_determined_applications_stage(families, year = Date.new.year)
            family_ids = families.distinct(:_id)
            Operations::Applications::LatestDeterminedApplicationsForFamiliesByYear.new.call({ family_ids: family_ids, assistance_year: year})
          end

          def fetch_mec_evidences(application_hbx_ids)
            Operations::Applications::MedicaidGateway::Pdm::MecEvidencesForApplicationHbxIds.new.call({ application_hbx_ids: application_hbx_ids })
          end

          def generate_report(evidences_hash)
            default_values = {
              'application_hbx_id' => '', 'family_id' => '', 'person_hbx_id' => '', 'current_evidence_aasm_state' => '', 'current_evidence_due_on' => '',
              'workflow_state_transition_1_from_state' => '', 'workflow_state_transition_1_to_state' => '', 'workflow_state_transition_1_event' => '', 'workflow_state_transition_1_transition_at' => '',
              'workflow_state_transition_2_from_state' => '', 'workflow_state_transition_2_to_state' => '', 'workflow_state_transition_2_event' => '', 'workflow_state_transition_2_transition_at' => '',
              'verification_history_action' => '', 'verification_history_update_reason' => '', 'verification_history_updated_by' => '',
              'verification_history_date_of_action' => '', 'request_result_result' => '', 'request_result_source' => '',
              'request_result_date_of_action' => ''
            }

            csv_content = CSV.generate(force_quotes: true) do |csv|
              csv << default_values.keys
              evidences_hash.map { |hash| default_values.merge(hash).values }.each { |row| csv << row }
            end

            file_name = "#{Rails.root}/local_mec_evidence_for_applicants_report_#{DateTime.now.strftime('%Y_%m_%d_%H_%M_%S')}.csv"
            File.write(file_name, csv_content)

            puts "Successfully Generated report report_name: #{file_name}"

            Success(file_name)
          rescue StandardError => e
            Failure("Failed to generate report due to #{e.inspect}")
          end
        end
      end
    end
  end
end
