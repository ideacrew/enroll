# frozen_string_literal: true

module Operations
  module HbxAdmin
    module DryRun
      module Individual
      # This Operation is responsible for getting enrollment data for individual market.
        class EnrollmentsPipeline
          include Dry::Monads[:do, :result]
          include L10nHelper

          # Calls the NoticeQuery operation.
          #
          # @param params [Hash] The parameters for the query.
          # @option params [Date] :effective_on The effective_on for the query.
          # @option params [Array<String>] :aasm_states The aasm_states for the query.
          # @return [Dry::Monads::Result] The result of the operation.
          def call(params)
            validated_params = yield validate(params)
            pipeline = yield pipeline(validated_params)

            Success(pipeline)
          end

          private

          # Validates the input parameters.
          #
          # @param params [Hash] The parameters to validate.
          # @return [Dry::Monads::Result] The result of the validation.
          def validate(params)
            return Failure("Effective On cannot be blank") if params[:effective_on].blank?
            return Failure("AASM States cannot be blank") if params[:aasm_states].blank?

            Success(params)
          end

          # Builds the MongoDB aggregation pipeline.
          #
          # @param params [Hash] The validated parameters.
          # @return [Array<Hash>] The aggregation pipeline.
          def pipeline(params)
            effective_on = params[:effective_on]
            aasm_states = params[:aasm_states]

            Success([
              match_stage(effective_on, aasm_states),
              group_stage_1,
              group_stage_2,
              project_stage
            ])
          rescue StandardError => e
            Failure(["pipeline: error: #{e.message}", {}])
          end

          def match_stage(effective_on, aasm_states)
            {
              '$match' => {
                'kind' => 'individual',
                'effective_on' => {
                  '$gte' => effective_on.beginning_of_year,
                  '$lte' => effective_on.end_of_year
                },
                'aasm_state' => { '$in' => aasm_states }
              }
            }
          end

          def group_stage_1
            {
              '$group' => {
                '_id' => {
                  'aasm_state' => '$aasm_state',
                  'coverage_kind' => '$coverage_kind',
                  'applied_aptc_greater_than_zero' => {
                    '$cond' => [{ '$gt' => ['$applied_aptc_amount.cents', 0] }, true, false]
                  }
                },
                'count' => { '$sum' => 1 }
              }
            }
          end

          def group_stage_2
            {
              '$group' => {
                '_id' => '$_id.coverage_kind',
                'states' => {
                  '$push' => {
                    'state' => '$_id.aasm_state',
                    'applied_aptc' => '$_id.applied_aptc_greater_than_zero',
                    'count' => '$count'
                  }
                }
              }
            }
          end

          def project_stage
            {
              '$project' => {
                '_id' => 0,
                'coverage_kind' => '$_id',
                'without_aptc' => {
                  '$arrayToObject' => {
                    '$map' => {
                      'input' => {
                        '$filter' => {
                          'input' => '$states',
                          'as' => 'state',
                          'cond' => { '$eq' => ['$$state.applied_aptc', false] }
                        }
                      },
                      'as' => 'state',
                      'in' => {
                        'k' => '$$state.state',
                        'v' => '$$state.count'
                      }
                    }
                  }
                },
                'with_aptc' => {
                  '$arrayToObject' => {
                    '$map' => {
                      'input' => {
                        '$filter' => {
                          'input' => '$states',
                          'as' => 'state',
                          'cond' => { '$eq' => ['$$state.applied_aptc', true] }
                        }
                      },
                      'as' => 'state',
                      'in' => {
                        'k' => '$$state.state',
                        'v' => '$$state.count'
                      }
                    }
                  }
                }
              }
            }
          end
        end
      end
    end
  end
end