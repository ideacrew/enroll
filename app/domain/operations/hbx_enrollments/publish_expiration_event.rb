# frozen_string_literal: true

module Operations
  module HbxEnrollments
    # Publish expiration event for each enrollment
    class PublishExpirationEvent
      include EventSource::Command
      include Dry::Monads[:result, :do]

      # @param [Hash] params
      # @option params [Hash] :enrollment, :job
      # @return [Dry::Monads::Result]
      # @example params: { enrollment: HbxEnrollment.new, job: Transmittable::Job.new }
      def call(params)
        values       = yield validate(params)
        transmission = yield create_transmission(values[:enrollment], values[:job])
        transaction  = yield create_transaction(values[:enrollment], transmission)
        event        = yield build_event(values, transmission, transaction)
        result       = yield publish_event(values[:enrollment], event)

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

      def create_transmission(enrollment, job)
        ::Operations::Transmittable::CreateTransmission.new.call(
          {
            job: job,
            key: :hbx_enrollments_expiration_request,
            title: "Transmission request to expire enrollment with hbx id: #{enrollment.hbx_id}.",
            description: "Transmission request to expire enrollment with hbx id: #{enrollment.hbx_id}.",
            publish_on: Date.today,
            started_at: DateTime.now,
            event: 'initial',
            state_key: :initial,
            transmission_id: enrollment.hbx_id,
            correlation_id: enrollment.hbx_id,
          }
        )
      end

      def create_transaction(enrollment, transmission)
        ::Operations::Transmittable::CreateTransaction.new.call(
          {
            transmission: transmission,
            subject: enrollment,
            key: :hbx_enrollments_expiration_request,
            title: "Enrollment expiration request transaction for #{enrollment.hbx_id}.",
            description: "Transaction request to expire enrollment with hbx id: #{enrollment.hbx_id}.",
            publish_on: Date.today,
            started_at: DateTime.now,
            event: 'initial',
            state_key: :initial,
          }
        )
      end

      def build_event(values, transmission, transaction)
        event(
          'events.individual.enrollments.expire_coverages.expire',
          attributes: {
            enrollment_gid: values[:enrollment].to_global_id.uri,
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
        Success("Published expiration event: #{event.name} for enrollment with gid: #{enrollment.to_global_id.uri}.")
      end
    end
  end
end
