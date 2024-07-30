# frozen_string_literal: true

module Operations
  module Transmittable
    # create Transaction that takes params of key (required), started_at(required), and transmission (required)
    class CreateTransaction
      include Dry::Monads[:do, :result]

      def call(params)
        values = yield validate_params(params)
        process_status = yield create_process_status(values[:event], values[:state_key])
        transaction_hash = yield build_transaction_hash(values, process_status)
        transaction_entity = yield create_transaction_entity(transaction_hash)
        transaction = yield create_transaction(transaction_entity, values[:subject])
        _transaction_transmission = yield create_transaction_transmission(transaction, values[:transmission])
        Success(transaction)
      end

      private

      def validate_params(params)
        return Failure('Transaction cannot be created without key symbol') unless params[:key].is_a?(Symbol)
        return Failure('Transaction cannot be created without started_at datetime') unless params[:started_at].is_a?(DateTime)
        return Failure('Transaction cannot be created without a transmission') unless params[:transmission].is_a?(::Transmittable::Transmission)
        return Failure('Transaction cannot be created without a subject') unless params[:subject]
        return Failure('Transaction cannot be created without event string') unless params[:event].is_a?(String)
        return Failure('Transaction cannot be created without state_key symbol') unless params[:state_key].is_a?(Symbol)

        Success(params)
      end

      def build_transaction_hash(values, process_status)
        Success({
                  key: values[:key],
                  title: values[:title],
                  description: values[:description],
                  process_status: process_status,
                  started_at: values[:started_at],
                  transaction_id: values[:correlation_id],
                  ended_at: values[:ended_at],
                  transmittable_errors: [],
                  json_payload: nil,
                  xml_payload: nil
                })
      end

      def create_process_status(event, state_key)
        result = Operations::Transmittable::CreateProcessStatusHash.new.call({ event: event, state_key: state_key, started_at: DateTime.now,
                                                                               message: 'created transaction' })
        result.success? ? Success(result.value!) : result
      end

      def create_transaction_entity(transaction_hash)
        validation_result = AcaEntities::Protocols::Transmittable::Operations::Transactions::Create.new.call(transaction_hash)

        validation_result.success? ? Success(validation_result.value!) : validation_result
      end

      def create_transaction(transaction_entity, subject)
        Success(subject.transactions.create(transaction_entity.to_h))
      end

      def create_transaction_transmission(transaction, transmission)
        Success(::Transmittable::TransactionsTransmissions.create(
                  transmission: transmission,
                  transaction: transaction
                ))
      end
    end
  end
end
