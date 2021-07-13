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
          Rails.logger.info("Invoked CreateEligibilityResponseModel with #{params.inspect}")
          value = yield construct_payload_hash(params)
          validated_params = yield validate_value(value)
          entity = yield create_entity(validated_params)
          model = yield persist(entity)

          Success(model)
        end

        private

<<<<<<< HEAD
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
=======
        def construct_payload_hash(params)
          value = {
            primary_member_hbx_id: a[:primary_member_hbx_id],
            event_kind: a[:event_kind],
            ridp_eligibility: {
              delivery_info: a[:delivery_info],
              metadata: a[:metadata],
              event: a[:response]
>>>>>>> 2acebe3e3e (fixed spec and added extra logger)
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
<<<<<<< HEAD
            Rails.logger.info("Persisting EligibilityResponseModel with #{entity}")
=======
            Rails.logger.info("Persisting EligibilityResponseModel with #{entity.to_h}")
>>>>>>> 2acebe3e3e (fixed spec and added extra logger)
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
