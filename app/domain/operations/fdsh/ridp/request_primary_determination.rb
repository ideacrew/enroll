# frozen_string_literal: true

require 'dry/monads'
require 'dry/monads/do'

module Operations
  module Fdsh
    module Ridp
      # ridp primary request
      class RequestPrimaryDetermination
        # primary request from fdsh gateway

        include Dry::Monads[:do, :result]
        include Acapi::Notifiers

        # @param [ Hash ] params Applicant Attributes
        # @return [ BenefitMarkets::Entities::Applicant ] applicant Applicant
        def call(params)
          payload_param = yield construct_payload_hash(params)
          payload_value = yield validate_payload(payload_param)
          payload_entity = yield create_payload_entity(payload_value)
          payload = yield publish(payload_entity)

          Success(payload)
        end

        private

        def construct_payload_hash(family)
          if family.is_a?(::Family)
            Operations::Transformers::FamilyTo::Cv3Family.new.call(family)
          else
            Failure("Invalid Family Object #{family}")
          end
        end

        def validate_payload(value)
          result = AcaEntities::Contracts::Families::FamilyContract.new.call(value)
          if result.success?
            Success(result)
          else
            hbx_id = value[:family_members].detect{|a| a[:is_primary_applicant] == true}[:person][:hbx_id]
            Failure("Person with hbx_id #{hbx_id} is not valid due to #{result.errors.to_h}.")
          end
        end

        def create_payload_entity(value)
          Success(AcaEntities::Families::Family.new(value.to_h))
        end

        def publish(payload)
          Operations::Fdsh::Ridp::PublishPrimaryRequest.new.call(payload)
        end
      end
    end
  end
end
