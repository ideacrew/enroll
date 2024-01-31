# frozen_string_literal: true

module Operations
  module Transmittable
    # find or create job, then create response transmission/transaction, save payload and link to subject
    class GenerateResponseObjects
      include Dry::Monads[:result, :do, :try]

      def call(params)
        values = yield validate_params(params)
        @job = yield find_or_create_job_by_job_id(values)
        transmission_params = values.merge({ job: @job, event: 'acked', state_key: :acked })
        @transmission = yield create_response_transmission(transmission_params)
        subject = yield find_subject(params[:subject_type], params[:correlation_id])
        transaction_params = values.merge({ transmission: @transmission, subject: subject, event: 'acked', state_key: :acked })
        @transaction = yield create_response_transaction(transaction_params, { job: @job, transmission: @transmission })

        transmittable
      end

      private

      def validate_params(params)
        return Failure('Cannot save a failure response without a payload') if params[:payload].blank?
        return Failure('Cannot save a failure response without a key') unless params[:key].is_a?(Symbol)
        # might need to send additional info to link with correct subject
        return Failure('Cannot link a subject without a correlation_id') unless params[:correlation_id].is_a?(String)
        return Failure('Cannot link a subject without a subject_type') unless params[:subject_type].is_a?(String)

        Success({ key: params[:key],
                  title: params[:key].humanize.titleize,
                  correlation_id: params[:correlation_id],
                  started_at: DateTime.now,
                  publish_on: DateTime.now,
                  job_id: params[:job_id]})
      end

      def find_subject(type, correlation_id)
        # double check on calls the logic for the possible subject types
        # other possibility is move this out of this operation and send the subject itself
        subject = case type
                  when "person"
                    Person.by_hbx(correlation_id)&.last
                  when "application"
                    # to do: double check this logic if it is id/hbx_id/primary hbx_id etc
                    FinancialAssistance::Application.where(_id: correlation_id)
                  when "family"
                    # to do: add this
                  end
        return Success(subject) if subject
        add_errors(:find_subject, "Failed to find subject", { job: @job, transmission: @transmission })
        status_result = update_status(result.failure, :failed, { job: @job, transmission: @transmission })
        return status_result if status_result.failure?
        Failure("Failed to find subject")
      end

      def transmittable
        if @transaction.json_payload
          Success({ transaction: @transaction,
                    transmission: @transmission,
                    job: @job})
        else
          add_errors({ job: @job, transmission: @transmission, transaction: @transaction },
                     "Transaction does not have a payload",
                     :transmittable)
          status_result = update_status({ job: @job, transmission: @transmission, transaction: @transaction }, :failed,
                                        "Transaction does not have a payload")
          return status_result if status_result.failure?
          Failure("Transaction does not have a payload")
        end
      end

    end
  end
end
