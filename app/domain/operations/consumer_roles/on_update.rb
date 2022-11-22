# frozen_string_literal: true

require 'dry/monads'
require 'dry/monads/do'

module Operations
  module ConsumerRoles
    # This class is to Trigger all ConsumerRole OnUpdate events.
    class OnUpdate
      include Dry::Monads[:result, :do]

      def call(params)
        values                   = yield validate_params(params)
        logger                   = yield fetch_logger(values)
        _triggered_verifications = yield determine_verifications(values[:payload], logger)

        Success('Triggered ConsumerRole OnUpdate Events')
      end

      private

      def validate_params(params)
        if !params[:payload].is_a?(Hash) || !params[:subscriber_logger].is_a?(Logger)
          Failure("Invalid params: #{params}. Must have keys :payload(should be an instance if Hash) and :subscriber_logger(should be an instance if Logger)")
        else
          Success(params)
        end
      end

      def fetch_logger(values)
        Success(values[:subscriber_logger])
      end

      def determine_verifications(payload, logger)
        return Failure("Unable to find gid: #{payload[:gid]}") if payload[:gid].blank?

        role = GlobalID::Locator.locate(payload[:gid])
        return Success("Consumer's applicant status did not change") unless payload[:previous].key?(:is_applying_coverage)

        return Success('Consumer is not applying for coverage.') if payload[:previous].key?(:is_applying_coverage) && !role.is_applying_coverage

        result = ::Operations::Individual::DetermineVerifications.new.call(
          { id: role.id, skip_rr_config_and_active_enrollment_check: true }
        )

        if result.success?
          logger.info "ConsumerRole DetermineVerifications success: #{result.success}"
        else
          logger.info "ConsumerRole DetermineVerifications failure: #{result.failure}"
        end

        Success('Triggered ConsumerRole DetermineVerifications')
      end
    end
  end
end
