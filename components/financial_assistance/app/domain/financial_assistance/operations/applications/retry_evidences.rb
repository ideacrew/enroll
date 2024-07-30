# frozen_string_literal: true

require 'dry/monads'
require 'dry/monads/do'

module FinancialAssistance
  module Operations
    module Applications
      # This operation can be used to handle needed retries of evidences
      class RetryEvidences
        include Dry::Monads[:do, :result]

        # @param [Hash] opts The options to retry evidences
        # @option opts [Array] :applicants
        # @option opts [String] :modified_by (optional)
        # @option opts [String] :update_reason
        # @option opts [Symbol] :evidence_type
        # @return [Dry::Monads::Result]
        def call(params)
          validated_params = yield validate_input_params(params)
          update_evidences(validated_params)
        end

        private

        def validate_input_params(params)
          params[:modified_by] = params[:modified_by] || "system"
          return Failure("Missing or invalid param for key applicants, must be an array of applicants") unless params[:applicants].is_a?(Array)
          return Failure("Missing or invalid param for key evidence_type, must be a valid evidence_type") unless params[:evidence_type].is_a?(Symbol)
          return Failure("Invalid param for key modified_by, must be a String") unless params[:modified_by].is_a?(String)
          return Failure("Missing or invalid param for key update_reason, must be a String") unless params[:update_reason].is_a?(String)
          Success(params)
        end

        def update_evidences(params)
          params[:applicants].each do |applicant|
            evidence = applicant.fetch_evidence("#{params[:evidence_type]}_evidence")
            next unless evidence
            request = evidence.request_determination("retry", params[:update_reason], params[:modified_by])
            next if request
          end
          Success("Published request determinations for retries")
        rescue StandardError => e
          Failure("Failed to retry evidences due to #{e.message}")
        end
      end
    end
  end
end
