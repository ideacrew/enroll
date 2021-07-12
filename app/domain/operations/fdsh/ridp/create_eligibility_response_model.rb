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
          value = yield construct_payload_hash(params)
          validated_params = yield validate_value(value)
          entity = yield create_entity(validated_params)
          model = yield persist(entity)

          Success(model)
        end

        private

        def construct_payload_hash(params)
          value = {
            primary_member_hbx_id: params[:primary_member_hbx_id],
            event_kind: params[:event_kind],
            ridp_eligibility: {
              delivery_info: params[:delivery_info],
              metadata: params[:metadata],
              event: params[:response]
            }
          }

          Success(value)
        end

        def validate_value(params)
          result = ::Validators::RidpEligibilityResponseContract.new.call(params)
          result.success? ? Success(result) : Failure("Invalid RidpEligibilitiyResponse due to #{result.errors.to_h}")
        end

        def create_entity(values)
          Success(::Entities::RidpEligibilityResponse.new(values.to_h))
        end

        def persist(entity)
          result = Try do
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
