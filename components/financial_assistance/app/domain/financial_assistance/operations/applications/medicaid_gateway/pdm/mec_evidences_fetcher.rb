# frozen_string_literal: true

# Operations::Applications::MedicaidGateway::Pdm::MecEvidencesForApplicationHbxIds.new.call({application_hbx_ids: [1, 2, 3]})
module Operations
  module Applications
    module MedicaidGateway
      module Pdm
        # This operation fetches the local mec evidences for the given application hbx ids
        class MecEvidencesFetcher
          include Dry::Monads[:do, :result, :try]

          def call(params)
            application_hbx_ids = yield validate(params)
            pipeline = yield build_pipeline(application_hbx_ids)
            applicants_local_mec_evidence_hash = yield execute(pipeline)

            Success(applicants_local_mec_evidence_hash)
          end

          private

          def validate(params)
            application_hbx_ids = params[:application_hbx_ids]

            return Failure('application_hbx_ids is missing') unless application_hbx_ids.present?

            Success(application_hbx_ids)
          end

          def build_pipeline(application_hbx_ids)
            pipeline = [
              match_stage(application_hbx_ids),
              unwind_stage,
              group_stage,
              project_stage
            ]

            Success(pipeline)
          rescue StandardError => e
            Failure("Failed to build pipeline due to #{e.inspect}")
          end

          def execute(pipeline)
            local_mec_evidences = aggregate_collection(::FinancialAssistance::Application.collection, pipeline)

            if local_mec_evidences.present?
              Success(local_mec_evidences)
            else
              Failure('No local_mec_evidences found')
            end
          rescue StandardError => e
            Failure("Failed to fetch local_mec_evidences due to #{e.inspect}")
          end

          def aggregate_collection(collection, pipeline)
            collection.aggregate(pipeline, allow_disk_use: true).to_a
          end

          def match_stage(application_hbx_ids)
            { '$match' => { 'hbx_id' => { '$in' => application_hbx_ids } } }
          end

          def unwind_stage
            { '$unwind' => '$applicants' }
          end

          def group_stage
            {
              '$group' => {
                '_id' => group_id_fields,
                'current_evidence_aasm_state' => first_field('$applicants.local_mec_evidence.aasm_state'),
                'current_evidence_due_on' => first_field('$applicants.local_mec_evidence.due_on'),
                'workflow_state_transition_1' => first_sorted_array_elem('$applicants.local_mec_evidence.workflow_state_transitions', -1),
                'workflow_state_transition_2' => first_sorted_array_elem('$applicants.local_mec_evidence.workflow_state_transitions', -2),
                'verification_history' => first_array_elem('$applicants.local_mec_evidence.verification_histories', -1),
                'request_result' => first_array_elem('$applicants.local_mec_evidence.request_results', -1)
              }
            }
          end

          def sort_stage
            { '$sort' => { '_id.application_hbx_id' => 1 } }
          end

          def project_stage
            {
              '$project' => {
                '_id' => 0,
                'family_id' => '$_id.family_id',
                'person_hbx_id' => '$_id.person_hbx_id',
                'application_hbx_id' => '$_id.application_hbx_id'
              }.merge(local_mec_fields)
            }
          end

          def local_mec_fields
            {
              'current_evidence_aasm_state' => 1,
              'current_evidence_due_on' => 1
            }.merge(local_mec_workflow_fields).merge(local_mec_verification_fields)
          end

          def local_mec_workflow_fields
            (1..2).each_with_object({}) do |i, fields|
              fields["workflow_state_transition_#{i}_from_state"] = "$workflow_state_transition_#{i}.from_state"
              fields["workflow_state_transition_#{i}_to_state"] = "$workflow_state_transition_#{i}.to_state"
              fields["workflow_state_transition_#{i}_event"] = "$workflow_state_transition_#{i}.event"
              fields["workflow_state_transition_#{i}_transition_at"] = "$workflow_state_transition_#{i}.transition_at"
            end
          end

          def local_mec_verification_fields
            {
              'verification_history_action' => '$verification_history.action',
              'verification_history_update_reason' => '$verification_history.update_reason',
              'verification_history_updated_by' => '$verification_history.updated_by',
              'verification_history_date_of_action' => '$verification_history.date_of_action',
              'request_result_result' => '$request_result.result',
              'request_result_source' => '$request_result.source',
              'request_result_date_of_action' => '$request_result.date_of_action'
            }
          end

          def group_id_fields
            {
              'family_id' => '$family_id',
              'person_hbx_id' => '$applicants.person_hbx_id',
              'application_hbx_id' => '$hbx_id'
            }
          end

          def first_field(field)
            { '$first' => field }
          end

          def first_array_elem(array_field, index)
            { '$first' => { '$arrayElemAt' => [array_field, index] } }
          end

          def first_sorted_array_elem(array_field, index)
            {
              '$first' => {
                '$arrayElemAt' => [
                  {
                    '$sortArray' => {
                      'input' => array_field,
                      'sortBy' => { 'transition_at' => 1 }
                    }
                  },
                  index
                ]
              }
            }
          end
        end
      end
    end
  end
end



