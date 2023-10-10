# initialize vlp documents
# frozen_string_literal: true

require 'dry/monads'
require 'dry/monads/do'

module Operations
  module People
    class InitializeVlpDocument
      include Dry::Monads[:result, :do]

      def call(params)
        contract = yield validate(params)
        entity = yield create_entity(contract)

        Success(entity)
      end

      private

      def sanitize_params(params)
        params[:subject] = params.delete :vlp_subject if params[:vlp_subject]
        params[:description] = params.delete :vlp_description if params[:vlp_description]
        params
      end

      def validate(params)
        contract = Validators::Families::VlpDocumentContract.new.call(sanitize_params(params))

        if contract.success?
          Success(contract)
        else
          Failure(contract)
        end
      end

      def create_entity(contract)
        entity = Entities::VlpDocument.new(contract.to_h)

        Success(entity)
      rescue StandardError => e
        Failure("create_entity error: #{e}")
      end
    end
  end
end