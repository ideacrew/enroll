# frozen_string_literal: true

module Operations
  module HbxEnrollments
    # Publish expiration event for each enrollment
    class PublishExpirationEvent
      include ::Operations::Transmittable::TransmittableUtils

      attr_reader :transaction, :transmission

      # @param [Hash] params
      # @option params [Hash] :enrollment, :job
      # @return [Dry::Monads::Result]
      # @example params: { enrollment: HbxEnrollment.new, job: Transmittable::Job.new }
      def call(params)
        values              = yield validate(params)
        transmission_params = yield construct_transmission_params(values[:enrollment], values[:job])
        @transmission       = yield create_request_transmission(transmission_params, values[:job])
        transaction_params  = yield construct_transaction_params(values[:enrollment])
        @transaction        = yield create_request_transaction(transaction_params, values[:job])
        event               = yield build_event(values)
        result              = yield publish_event(values[:enrollment], event)

        Success(result)
      end

      private

      def validate(params)
        if params.is_a?(Hash) && params[:enrollment].is_a?(::HbxEnrollment) && params[:job].is_a?(::Transmittable::Job)
          Success(params)
        else
          Failure("Invalid input params: #{params}. Expected a hash.")
        end
      end

      def construct_transmission_params(enrollment, job)
        Success(
          {
            job: job,
            key: :hbx_enrollment_expiration_request,
            title: "Transmission request to expire enrollment with hbx id: #{enrollment.hbx_id}.",
            description: "Transmission request to expire enrollment with hbx id: #{enrollment.hbx_id}.",
            publish_on: Date.today,
            started_at: DateTime.now,
            event: 'initial',
            state_key: :initial,
            correlation_id: enrollment.hbx_id
          }
        )
      end

      def construct_transaction_params(enrollment)
        Success(
          {
            transmission: transmission,
            subject: enrollment,
            key: :hbx_enrollment_expiration_request,
            title: "Enrollment expiration request transaction for #{enrollment.hbx_id}.",
            description: "Transaction request to expire enrollment with hbx id: #{enrollment.hbx_id}.",
            publish_on: Date.today,
            started_at: DateTime.now,
            event: 'initial',
            state_key: :initial,
            correlation_id: enrollment.hbx_id
          }
        )
      end

      def build_event(values)
        event(
          'events.individual.enrollments.expire_coverages.expire',
          attributes: {
            enrollment_gid: values[:enrollment].to_global_id.uri,
            enrollment_hbx_id: values[:enrollment].hbx_id,
            transmittable_identifiers: {
              job_gid: values[:job].to_global_id.uri,
              transmission_gid: transmission.to_global_id.uri,
              transaction_gid: transaction.to_global_id.uri,
              subject_gid: values[:enrollment].to_global_id.uri
            }
          }
        )
      end

      def publish_event(enrollment, event)
        event.publish
        Success("Successfully published expiration event: #{event.name} for enrollment with hbx_id: #{enrollment.hbx_id}.")
      end
    end
  end
end
