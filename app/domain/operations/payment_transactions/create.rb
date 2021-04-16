# frozen_string_literal: true

require 'dry/monads'
require 'dry/monads/do'
require 'aca_entities/contracts/financial/payment_transactions/payment_transaction_contract'
require 'aca_entities/financial/payment_transactions/payment_transaction'

module Operations
  # module for payment transaction operations
  module PaymentTransactions
    # Creates a payment transaction for a family when given a valid enrollment.
    class Create
      include Config::SiteConcern
      send(:include, Dry::Monads[:result, :do])

      def call(params)
        validated_source                = yield validate_source(params[:source])
        validated_enrollment            = yield validate_hbx_enrollment(params[:hbx_enrollment])
        transaction_params              = yield construct_transaction_payload(validated_enrollment, validated_source)
        validated_transaction_payload   = yield validate_transaction_payload(transaction_params)
        transaction_entity              = yield create_transaction_entity(validated_transaction_payload)
        payment                         = yield create(validated_enrollment, transaction_entity)

        Success(payment)
      end

      private

      def validate_source(source)
        return Failure('Is not a source object') unless source.is_a?(String)

        Success(source)
      end

      def validate_hbx_enrollment(enrollment)
        return Failure('Is not a hbx enrollment object') unless enrollment.is_a?(HbxEnrollment)

        Success(enrollment)
      end

      def construct_transaction_payload(enrollment, source)
        Success({ :enrollment_id => enrollment&.id&.to_s,
                  :carrier_id => enrollment&.product&.issuer_profile_id&.to_s,
                  :enrollment_effective_date => enrollment&.effective_on,
                  :source => source})
      end

      def validate_transaction_payload(params)
        result = ::AcaEntities::Contracts::Financial::PaymentTransactions::PaymentTransactionContract.new.call(params)
        result.success? ? Success(result.to_h) : Failure(result.errors.to_h)
      end

      def create_transaction_entity(params)
        transaction = ::AcaEntities::Financial::PaymentTransactions::PaymentTransaction.new(params)
        Success(transaction)
      end

      def create(hbx_enrollment, transaction_entity)
        payment = hbx_enrollment.family.payment_transactions.create(transaction_entity.to_h)
        Success(payment)
      end
    end
  end
end
