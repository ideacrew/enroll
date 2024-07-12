# frozen_string_literal: true

module Operations
  module Transmittable
    # create job operation that takes params of key (required), started_at(required),
    # publish_on(required), message_id (optional) and job_id (optional)
    class FindOrCreateJob
      include Dry::Monads[:do, :result]

      def call(params)
        values = yield validate_params(params)
        job = yield find_or_create_job(values)
        Success(job)
      end

      private

      def validate_params(params)
        return Failure('key required') unless params[:key].is_a?(Symbol)
        return Failure('started_at required') unless params[:started_at].is_a?(DateTime)
        return Failure('publish_on required') unless params[:publish_on].is_a?(DateTime)
        # message_id is optional, so can be nil but not an empty string.
        return Failure('message_id cannot be empty string') if params.key?(:message_id) && !params[:message_id].nil? && params[:message_id].blank?
        return Failure('message_id should be a string') if params[:message_id].present? && !params[:message_id].is_a?(String)
        Success(params)
      end

      def find_or_create_job(values)
        if values[:job_id]
          job = ::Transmittable::Job.where(job_id: values[:job_id]).last

          job ? Success(job) : create_job(values)

        elsif values[:message_id]
          job = ::Transmittable::Job.where(message_id: values[:message_id]).last

          job ? Success(job) : create_job(values)
        else
          create_job(values)
        end
      end

      def create_job(values)
        Operations::Transmittable::CreateJob.new.call(values)
      end
    end
  end
end