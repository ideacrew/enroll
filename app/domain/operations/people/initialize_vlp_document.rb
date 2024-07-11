# initialize vlp documents
# frozen_string_literal: true

require 'dry/monads'
require 'dry/monads/do'

module Operations
  module People
    # Class for initializing a new VLP document
    class InitializeVlpDocument
      include Dry::Monads[:do, :result]

      # Initializes a new VLP document.
      #
      # @param params [Hash] The parameters for initializing the VLP document.
      # @option params [String] :subject The subject of the VLP document required.
      # @return [Dry::Monads::Result] The result of the operation.
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
        hash = sanitize_params(params)
        return Success({}) if hash[:subject].blank?

        contract = Validators::Families::VlpDocumentContract.new.call(hash)

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