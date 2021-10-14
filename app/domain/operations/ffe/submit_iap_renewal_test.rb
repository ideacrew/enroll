# frozen_string_literal: true

require 'dry/monads'
require 'dry/monads/do'

module Operations
  module Ffe
    # This Operation renews a renewal_draft application i.e. submits a renewal_draft application.
    class SubmitIapRenewalTest
      include Dry::Monads[:result, :do, :try]
      include EventSource::Command

      # @param [Hash] opts The options to submit renewal_draft application
      # @option opts [Hash] :application
      # @return [Dry::Monads::Result]
      def call(params)
        application = yield find_application(params)
        payload = yield renew_application(application)

        Success(application)
      end

      private

      # TODO: Refactor code to use :hbx_id instead of :_id
      def find_application(params)
        return Failure("Input params is not a hash: #{params}") unless params.is_a?(Hash)
        return Failure('Missing application_id key') unless params.key?(:_id)
        application = ::FinancialAssistance::Application.find(params[:_id])
        return Failure("Cannot find Application with input value: #{params[:_id]} for key application_id") unless application
        Success(application)
      end

      def renew_application(application)
        if application.have_permission_to_renew?
          if application.may_submit? && application.is_application_valid?
            application.submit!
            Success(application)
          else
            Rails.logger.error "Unable to submit the application for given application hbx_id: #{application.hbx_id}"
            Failure("Unable to submit the application for given application hbx_id: #{application.hbx_id}, base_errors: #{application.errors.to_h}")
          end
        else
          application.set_income_verification_extension_required!
          Rails.logger.error "Expired Submission is failed for hbx_id: #{application.hbx_id}"
          Failure("Expired Submission is failed for hbx_id: #{application.hbx_id}")
        end
      end
    end
  end
end
