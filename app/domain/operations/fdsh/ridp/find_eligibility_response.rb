# frozen_string_literal: true

module Operations
  module Fdsh
    module Ridp
      # Checks database for RIDP eligibility responses
      class FindEligibilityResponse
        include Dry::Monads[:do, :result]

        # @param [String] member_id
        def call(params)
          eligibility_result = yield find_eligibility_response(params)
          ridp_response = yield build_ridp_response(eligibility_result)

          Success(ridp_response)
        end

        private

        def find_eligibility_response(params)
          response =
            ::Fdsh::Ridp::EligibilityResponseModel.where(
              '$and' => [
                { :event_kind => params[:event_kind] },
                { :primary_member_hbx_id => params[:primary_member_hbx_id] },
                { :deleted_at => nil }
              ]
            ).max_by(&:updated_at)

          if response.present?
            response.update!(deleted_at: DateTime.now)
            Success(response)
          else
            Failure[:ridp_eligibility_response_not_found, values: params]
          end
        end

        def build_ridp_response(eligibility_result)
          entity = eligibility_result.serializable_hash.deep_symbolize_keys
          entity ? Success(entity) : Failure(entity)
        end
      end
    end
  end
end
