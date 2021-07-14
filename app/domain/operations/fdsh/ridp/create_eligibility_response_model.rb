# frozen_string_literal: true

require 'dry/monads'
require 'dry/monads/do'

module Operations
  module Fdsh
    module Ridp
      # This class will persist ridp responce to DB
      class CreateEligibilityResponseModel
        send(:include, Dry::Monads[:result, :do, :try])
        include EventSource::Command

        def call(params)
          Rails.logger.info("Invoked CreateEligibilityResponseModel with #{params.to_h.inspect}")
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
                metadata: params[:metadata],
                event: params[:response]
              }
            }

            Rails.logger.info("In construct_payload_hash method #{value}")

            Success(value)
          end.or(Failure("Invalid params to construct a payload for RidpEligibilityResponse"))
        end

        def validate_value(params)
          Rails.logger.info("in validate_value &&&&&&&&&&&&&&& #{params.to_h}")

          result = ::Validators::RidpEligibilityResponseContract.new.call(params.to_h)
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
