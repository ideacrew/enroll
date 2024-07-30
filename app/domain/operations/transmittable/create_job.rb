# frozen_string_literal: true

module Operations
  module Transmittable
    # create job operation that takes params of key (required), started_at(required), publish_on(required)
    class CreateJob
      include Dry::Monads[:do, :result]

      def call(params)
        values = yield validate_params(params)
        process_status = yield create_process_status
        job_hash = yield create_job_hash(values, process_status)
        job_entity = yield create_job_entity(job_hash)
        job = yield create_job(job_entity)
        Success(job)
      end

      private

      def validate_params(params)
        return Failure('Cannot create a job without a key as a symbol') unless params[:key].is_a?(Symbol)
        return Failure('Cannot create a job without a started_at as a DateTime') unless params[:started_at].is_a?(DateTime)
        return Failure('Cannot create a job without a publish_on as a DateTime') unless params[:publish_on].is_a?(DateTime)

        Success(params)
      end

      def create_job_hash(values, process_status)
        Success({
                  job_id: generate_job_id(values[:key]),
                  saga_id: values[:saga_id],
                  key: values[:key],
                  title: values[:title],
                  description: values[:description],
                  publish_on: values[:publish_on],
                  expire_on: values[:expire_on],
                  started_at: values[:started_at],
                  ended_at: values[:ended_at],
                  time_to_live: values[:time_to_live],
                  message_id: values[:message_id],
                  process_status: process_status,
                  transmittable_errors: [],
                  allow_list: [],
                  deny_list: []
                })
      rescue StandardError => e
        Rails.logger.error { "Couldn't create job #{e.backtrace}" }
      end

      def create_job_entity(job_hash)
        validation_result = AcaEntities::Protocols::Transmittable::Operations::Jobs::Create.new.call(job_hash)

        validation_result.success? ? Success(validation_result.value!) : validation_result
      end

      def generate_job_id(key)
        "#{key}_#{Time.now.to_i}"
      end

      def create_process_status
        result = Operations::Transmittable::CreateProcessStatusHash.new.call({ event: 'initial', state_key: :initial, started_at: DateTime.now,
                                                                               message: 'created job' })
        result.success? ? Success(result.value!) : result
      end

      def create_job(job_entity)
        job = ::Transmittable::Job.create(job_entity.to_h)
        job.save ? Success(job) : Failure("Unable to save job due to invalid params")
      end
    end
  end
end