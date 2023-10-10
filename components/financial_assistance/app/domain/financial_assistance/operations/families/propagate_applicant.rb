# frozen_string_literal: true

require 'dry/monads'
require 'dry/monads/do'

module FinancialAssistance
  module Operations
    module Families
      # Create of update a family member
      class PropagateApplicant
        include Dry::Monads[:result, :do]

        def call(params)
          contract = yield validate(params[:applicant_params])
          entity = yield build(contract)
          applicant_params = yield sanitize_params(entity.to_h, params)
          result = yield propagate_applicant(applicant_params)

          Success(result)
        end

        private

        def validate(params)
          result = FinancialAssistance::Validators::ApplicantContract.new.call(params)

          if result.success?
            Success(result.to_h)
          else
            Failure(result)
          end
        end

        def sanitize_params(applicant_params, params)
          applicant_params.merge!({is_primary_applicant: params[:is_primary_applicant], family_id: params[:family_id]})
          Success(applicant_params)
        end

        def build(contract)
          result = FinancialAssistance::Entities::Applicant.new(contract)

          Success(result)
        end

        def propagate_applicant(applicant_params)
          begin
            applicant_params.merge!(skip_consumer_role_callbacks: true)
            result = ::Operations::Families::CreateOrUpdateMember.new.call(applicant_params)
            return result if result.success?
          rescue StandardError => e
            Failure(e.message)
          end
          Success('A successful call was made to enroll to create or update a family member')
        end
      end
    end
  end
end