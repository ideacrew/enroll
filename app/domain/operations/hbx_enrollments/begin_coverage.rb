# frozen_string_literal: true

module Operations
  module HbxEnrollments
    # Begin IVL enrollment coverage
    class BeginCoverage
      include ::Operations::Transmittable::TransmittableUtils

      attr_reader :logger, :hbx_enrollment, :job, :request_transaction, :request_transmission, :response_transaction, :response_transmission

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
        _params                   = yield validate(params)
        @hbx_enrollment           = yield find_enrollment
        @job                      = yield find_job_by_global_id(@job_gid)
        @request_transmission     = yield find_transmission_by_global_id(@request_transmission_gid)
        _updated_result           = yield update_status("Transmittable::Transmission found with given global ID: #{@request_transmission_gid}",
                                                        :succeeded,
                                                        { transmission: @request_transmission })
        @request_transaction      = yield find_transaction_by_global_id(@request_transaction_gid)
        _updated_result           = yield update_status("Transmittable::Transaction found with given global ID: #{@request_transaction_gid}",
                                                        :succeeded,
                                                        { transaction: @request_transaction })
        transmission_params       = yield construct_response_transmission_params
        @response_transmission    = yield create_response_transmission(transmission_params, { job: job, transmission: request_transmission })
        transaction_params        = yield construct_response_transaction_params
        @response_transaction     = yield create_response_transaction(transaction_params, { job: job, transaction: request_transaction})
        begin_coverage_msg        = yield begin_coverage
        _response_updated_result  = yield update_status(begin_coverage_msg,
                                                        :succeeded,
                                                        { transaction: response_transaction, transmission: response_transmission })

        Success(begin_coverage_msg)
      end

      private

      def validate(params)
        @logger = Logger.new(
          "#{Rails.root}/log/begin_coverage_#{TimeKeeper.date_of_record.strftime('%Y_%m_%d')}.log"
        )

        logger.info "Processing begin coverage request with params: #{params}"

        unless params.is_a?(Hash)
          msg = "Invalid input params: #{params}. Expected a hash."
          logger.error msg
          return Failure(msg)
        end

        unless params[:transmittable_identifiers].is_a?(Hash)
          msg = "Invalid transmittable_identifiers in params: #{params}. Expected a hash."
          logger.error msg
          return Failure(msg)
        end

        if params[:enrollment_gid].blank?
          msg = "Missing enrollment_gid in params: #{params}."
          logger.error msg
          return Failure(msg)
        end

        if params[:transmittable_identifiers][:job_gid].blank?
          msg = "Missing job_gid in transmittable_identifiers of params: #{params}."
          logger.error msg
          return Failure(msg)
        end

        if params[:transmittable_identifiers][:transmission_gid].blank?
          msg = "Missing transmission_gid in transmittable_identifiers of params: #{params}."
          logger.error msg
          return Failure(msg)
        end

        if params[:transmittable_identifiers][:transaction_gid].blank?
          msg = "Missing transaction_gid in transmittable_identifiers of params: #{params}."
          logger.error msg
          return Failure(msg)
        end

        if params[:transmittable_identifiers][:subject_gid].blank?
          msg = "Missing subject_gid in transmittable_identifiers of params: #{params}."
          logger.error msg
          return Failure(msg)
        end

        @hbx_enrollment_gid       = params[:enrollment_gid]
        @job_gid                  = params[:transmittable_identifiers][:job_gid]
        @request_transmission_gid = params[:transmittable_identifiers][:transmission_gid]
        @request_transaction_gid  = params[:transmittable_identifiers][:transaction_gid]

        Success(params)
      end

      def find_enrollment
        hbx_enrollment = GlobalID::Locator.locate(@hbx_enrollment_gid)

        if hbx_enrollment.blank?
          Failure(
            "No HbxEnrollment found with given global ID: #{@hbx_enrollment_gid}"
          )
        elsif !hbx_enrollment.is_ivl_by_kind?
          Failure(
            "Failed to expire enrollment hbx id #{hbx_enrollment.hbx_id} - #{hbx_enrollment.kind} is not a valid IVL enrollment kind"
          )
        else
          Success(hbx_enrollment)
        end
      end

      def construct_response_transmission_params
        Success(
          {
            job: job,
            key: :hbx_enrollment_begin_coverage_response,
            title: "Transmission response to begin coverage for enrollment with hbx id: #{hbx_enrollment.hbx_id}.",
            description: "Transmission response to begin coverage for enrollment with hbx id: #{hbx_enrollment.hbx_id}.",
            publish_on: Date.today,
            started_at: DateTime.now,
            event: 'received',
            state_key: :received,
            correlation_id: hbx_enrollment.hbx_id
          }
        )
      end

      def construct_response_transaction_params
        Success(
          {
            transmission: response_transmission,
            subject: hbx_enrollment,
            key: :hbx_enrollment_begin_coverage_response,
            title: "Transaction response to begin coverage for enrollment with hbx id: #{hbx_enrollment.hbx_id}.",
            description: "Transaction response to begin coverage for enrollment with hbx id: #{hbx_enrollment.hbx_id}.",
            publish_on: Date.today,
            started_at: DateTime.now,
            event: 'received',
            state_key: :received,
            correlation_id: hbx_enrollment.hbx_id
          }
        )
      end

      def begin_coverage
        if hbx_enrollment.may_begin_coverage?
          hbx_enrollment.begin_coverage!
          msg = "Successfully began coverage for enrollment hbx id #{hbx_enrollment.hbx_id}."
          logger.info msg
          Success(msg)
        else
          msg = "Invalid Transition request. Failed to begin coverage for enrollment hbx id #{hbx_enrollment.hbx_id}."
          logger.error msg
          Failure(msg)
        end
      end
    end
  end
end
