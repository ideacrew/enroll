# frozen_string_literal: true

module Operations
  module HbxEnrollments
    # Publish event to begin IVL enrollment coverage
    class PublishBeginCoverageEvent
      include EventSource::Command
      include Dry::Monads[:result, :do]

      attr_reader :transaction, :transmission

      # @param [Hash] params
      # @option params [Hash] :enrollment, :job
      # @return [Dry::Monads::Result]
      # @example params: { enrollment: HbxEnrollment.new, job: Transmittable::Job.new }
      def call(params)
        values            = yield validate(params)
        @transmission     = yield create_transmission(values[:enrollment], values[:job])
        @transaction      = yield create_transaction(values[:enrollment])
        event             = yield build_event(values)
        result            = yield publish_event(event)
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
            key: :hbx_enrollments_begin_coverage,
            title: "Transmission request to begin coverage of enrollment with hbx id: #{enrollment.hbx_id}.",
            description: "Transmission request to begin coverage of enrollment with hbx id: #{enrollment.hbx_id}.",
            publish_on: Date.today,
            started_at: DateTime.now,
            event: 'initial',
            state_key: :initial,
            transmission_id: enrollment.hbx_id,
            correlation_id: enrollment.hbx_id
          }
        )
      end

      def create_transaction(enrollment)
        ::Operations::Transmittable::CreateTransaction.new.call(
          {
            transmission: transmission,
            subject: enrollment,
            key: :hbx_enrollments_begin_coverage,
            title: "Enrollment begin coverage request transaction for #{enrollment.hbx_id}.",
            description: "Transaction request to begin coverage of enrollment with hbx id: #{enrollment.hbx_id}.",
            publish_on: Date.today,
            started_at: DateTime.now,
            event: 'initial',
            state_key: :initial
          }
        )
      end

      def build_event(values)
        event = event(
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

        if event.success?
          event
        else
          Failure("Failure building event: #{event.failure}")
        end
      end

      def publish_event(event)
        result = event.publish
        if result
          Success("Successfully published begin coverage event.")
        else
          Failure("Failure publishing event.")
        end
      end
    end
  end
end
