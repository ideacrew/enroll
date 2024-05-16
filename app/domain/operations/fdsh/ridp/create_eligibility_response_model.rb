# frozen_string_literal: true

require 'dry/monads'
require 'dry/monads/do'

module Operations
  module Fdsh
    module Ridp
      # This class will persist ridp responce to DB
      class CreateEligibilityResponseModel
        include Dry::Monads[:do, :result, :try]
        include EventSource::Command

        def call(params)
          value = yield construct_payload_hash(params)
          validated_params = yield validate_value(value)
          entity = yield create_entity(validated_params)
          model = yield persist(entity)

          Success(model)
        end

        private

        def construct_payload_hash(eligibility_json)
          params = JSON.parse(eligibility_json, :symbolize_names => true)
          Try do
            value = {
              primary_member_hbx_id: params[:primary_member_hbx_id],
              event_kind: params[:event_kind],
              ridp_eligibility: {
                metadata: params[:metadata].to_h,
                event: params[:response]
              }
            }
            Success(value)
          end.or(Failure("Invalid params to construct a payload for RidpEligibilityResponse"))
        end

        def validate_value(params)
          result = ::Validators::RidpEligibilityResponseContract.new.call(params.value!)
          result.success? ? Success(result) : Failure("Invalid RidpEligibilitiyResponse due to #{result.errors.to_h}")
        end

        def create_entity(values)
          Success(::Entities::RidpEligibilityResponse.new(values.to_h))
        end

        def persist(entity)
          result = Try do
            Rails.logger.info("Persisting EligibilityResponseModel with #{entity}")
            ::Fdsh::Ridp::EligibilityResponseModel.create!(entity.to_h)
          end

          result.or do
            Failure(:invalid_json)
          end
        end
      end
    end
  end
end