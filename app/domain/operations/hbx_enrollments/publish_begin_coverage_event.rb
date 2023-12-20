# frozen_string_literal: true

module Operations
  module HbxEnrollments
    # Publish event to begin IVL enrollment coverage
    class PublishBeginCoverageEvent
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
            key: :hbx_enrollment_begin_coverage_request,
            title: "Transmission request to begin coverage enrollment with hbx id: #{enrollment.hbx_id}.",
            description: "Transmission request to begin coverage enrollment with hbx id: #{enrollment.hbx_id}.",
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
            key: :hbx_enrollment_begin_coverage_request,
            title: "Enrollment begin coverage request transaction for #{enrollment.hbx_id}.",
            description: "Transaction request to begin coverage of enrollment with hbx id: #{enrollment.hbx_id}.",
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
          'events.individual.enrollments.begin_coverages.begin',
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
        Success("Successfully published begin coverage event: #{event.name} for enrollment with hbx_id: #{enrollment.hbx_id}.")
      end
    end
  end
end
