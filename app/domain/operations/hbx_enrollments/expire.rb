# frozen_string_literal: true

module Operations
  module HbxEnrollments
    # Expire IVL enrollment coverage
    class Expire
      include ::Operations::Transmittable::TransmittableUtils

      attr_reader :hbx_enrollment, :response_transmission, :response_transaction

      # @param [Hash] params
      # @option params [Hash] :enrollment_gid
      # @option params [Hash] :transmittable_identifiers
      # @return [Dry::Monads::Result]
      # @example params: {
      #   enrollment_gid: 'gid://enroll/HbxEnrollment/65739e355b4dc03a97f26c3b',
      #   enrollment_hbx_id: '123456',
      #   transmittable_identifiers: {
      #    job_gid: 'gid://enroll/Transmittable::Job/65739e355b4dc03a97f26c3b',
      #    transmission_gid: 'gid://enroll/Transmittable::Transmission/65739e355b4dc03a97f26c3b',
      #    transaction_gid: 'gid://enroll/Transmittable::Transaction/65739e355b4dc03a97f26c3b',
      #    subject_gid: 'gid://enroll/HbxEnrollment/65739e355b4dc03a97f26c3b'
      #   }
      # }
      def call(params)
        values                  = yield validate(params)
        @hbx_enrollment         = yield find_enrollment(values[:enrollment_gid])
        job                     = yield find_job_by_global_id(values[:transmittable_identifiers][:job_gid])
        request_transmission    = yield find_and_update_request_transmission(values[:transmittable_identifiers][:transmission_gid],
                                                                             job)
        request_transaction     = yield find_and_update_request_transaction(values[:transmittable_identifiers][:transaction_gid],
                                                                            job, request_transmission)
        transmission_params     = yield construct_response_transmission_params(job)
        @response_transmission  = yield create_response_transmission(transmission_params,
                                                                     { job: job,
                                                                       transmission: request_transmission,
                                                                       transaction: request_transaction})
        transaction_params      = yield construct_response_transaction_params
        @response_transaction   = yield create_response_transaction(transaction_params,
                                                                    { job: job,
                                                                      transmission: request_transmission,
                                                                      transaction: request_transaction})
        result                   = yield expire_enrollment

        Success(result)
      end

      private

      def validate(params)
        unless params.is_a?(Hash)
          msg = "Invalid input params: #{params}. Expected a hash."
          return Failure(msg)
        end

        unless params[:transmittable_identifiers].is_a?(Hash)
          msg = "Invalid transmittable_identifiers in params: #{params}. Expected a hash."
          return Failure(msg)
        end

        if params[:enrollment_gid].blank?
          msg = "Missing enrollment_gid in params: #{params}."
          return Failure(msg)
        end

        if params[:transmittable_identifiers][:job_gid].blank?
          msg = "Missing job_gid in transmittable_identifiers of params: #{params}."
          return Failure(msg)
        end

        if params[:transmittable_identifiers][:transmission_gid].blank?
          msg = "Missing transmission_gid in transmittable_identifiers of params: #{params}."
          return Failure(msg)
        end

        if params[:transmittable_identifiers][:transaction_gid].blank?
          msg = "Missing transaction_gid in transmittable_identifiers of params: #{params}."
          return Failure(msg)
        end

        if params[:transmittable_identifiers][:subject_gid].blank?
          msg = "Missing subject_gid in transmittable_identifiers of params: #{params}."
          return Failure(msg)
        end

        Success(params)
      end

      def find_enrollment(enrollment_gid)
        hbx_enrollment = GlobalID::Locator.locate(enrollment_gid)

        if hbx_enrollment.blank?
          msg = "No HbxEnrollment found with given global ID: #{enrollment_gid}"
          Failure(msg)
        elsif !hbx_enrollment.is_ivl_by_kind?
          msg = "Failed to expire enrollment hbx id #{hbx_enrollment.hbx_id} - #{hbx_enrollment.kind} is not a valid IVL enrollment kind"
          Failure(msg)
        else
          Success(hbx_enrollment)
        end
      end

      def find_and_update_request_transmission(transmission_gid, job)
        transmission = find_transmission_by_global_id(transmission_gid)

        if transmission.success?
          status_result = update_status("Transmittable::Transmission found with given global ID: #{transmission_gid}",
                                        :succeeded,
                                        { transmission: transmission.value! })

          return status_result if status_result.failure?
          Success(transmission.value!)
        else
          add_errors(:invalid_transmission_on_enrollment_expire,
                     "No Transmittable::Transmission found with given global ID: #{transmission_gid}",
                     { job: job })
          status_result = update_status("No Transmittable::Transmission found with given global ID",
                                        :failed,
                                        { job: job })
          return status_result if status_result.failure?
          msg = "No Transmittable::Transmission found with given global ID: #{transmission_gid}"
          Failure(msg)
        end
      end

      def find_and_update_request_transaction(transaction_gid, job, request_transmission)
        transaction = find_transaction_by_global_id(transaction_gid)

        if transaction.success?
          status_result = update_status("Transmittable::Transaction found with given global ID: #{transaction_gid}",
                                        :succeeded,
                                        { transaction: transaction.value! })
          return status_result if status_result.failure?
          Success(transaction.value!)
        else
          add_errors(:invalid_transaction_on_enrollment_expire,
                     "No Transmittable::Transaction found with given global ID: #{transaction_gid}",
                     { transmission: request_transmission, job: job })
          status_result = update_status("No Transmittable::Transaction found with given global ID: #{transaction_gid}",
                                        :failed,
                                        { transmission: request_transmission, job: job })
          return status_result if status_result.failure?
          msg = "No Transmittable::Transaction found with given global ID: #{transaction_gid}"
          Failure(msg)
        end
      end

      def construct_response_transmission_params(job)
        Success({
                  job: job,
                  key: :hbx_enrollment_expiration_response,
                  title: "Transmission response to expire enrollment with hbx id: #{hbx_enrollment.hbx_id}.",
                  description: "Transmission response to expire enrollment with hbx id: #{hbx_enrollment.hbx_id}.",
                  publish_on: Date.today,
                  started_at: DateTime.now,
                  event: 'received',
                  state_key: :received,
                  transmission_id: hbx_enrollment.hbx_id,
                  correlation_id: hbx_enrollment.hbx_id
                })
      end

      def construct_response_transaction_params
        Success({
                  transmission: response_transmission,
                  subject: hbx_enrollment,
                  key: :hbx_enrollment_expiration_response,
                  title: "Enrollment expiration response transaction for #{hbx_enrollment.hbx_id}.",
                  description: "Transaction response to expire enrollment with hbx id: #{hbx_enrollment.hbx_id}.",
                  publish_on: Date.today,
                  started_at: DateTime.now,
                  event: 'received',
                  transaction_id: hbx_enrollment.hbx_id,
                  state_key: :received
                })
      end

      def expire_enrollment
        hbx_enrollment.expire_coverage!
        status_result = update_status("Successfully expired enrollment hbx id #{hbx_enrollment.hbx_id}",
                                      :succeeded,
                                      { transaction: response_transaction, transmission: response_transmission })
        return status_result if status_result.failure?
        Success("Successfully expired enrollment hbx id #{hbx_enrollment.hbx_id}")
      rescue StandardError => e
        add_errors(:expire_enrollment,
                   "Failed to expire enrollment hbx id #{hbx_enrollment.hbx_id} - #{e.message}",
                   { transaction: response_transaction, transmission: response_transmission })
        status_result = update_status("Failed to expire enrollment hbx id #{hbx_enrollment.hbx_id} - #{e.message}",
                                      :failed,
                                      { transaction: response_transaction, transmission: response_transmission })
        return status_result if status_result.failure?
        Failure("Failed to expire enrollment hbx id #{hbx_enrollment.hbx_id} - #{e.message}")
      end
    end
  end
end
