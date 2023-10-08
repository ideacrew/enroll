# frozen_string_literal: true

require 'dry/monads'
require 'dry/monads/do'

module Operations
  module People
    class InitializePerson
      include Dry::Monads[:result, :do]

      def call(applicant_params)
        contract = yield validate(applicant_params)
        result = yield create_entity(contract)

        Success(result)
      end

      private

      def sanitize_params(params)
        params[:hbx_id] = params.delete :person_hbx_id
        params
      end

      def validate(params)
        contract = Validators::PersonContract.new.call(sanitize_params(params))

        if contract.success?
          Success(contract)
        else
          Failure(contract)
        end
      end

      def create_entity(contract)
        entity = Entities::Person.new(contract.to_h)

        Success(entity)
      end
    end
  end
end