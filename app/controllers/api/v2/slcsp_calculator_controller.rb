# frozen_string_literal: true

module Api
  module V2
    # This class handles the SLCSP Calculator API, this returns an estimate of payments for premiums for the year requested
    class SlcspCalculatorController < ApiBaseController
      skip_before_action :require_login
      skip_before_action :verify_authenticity_token

      def estimate
        params_parsed = JSON.parse(request.body.read)
        response = Operations::SlcspCalculation.new.call(params_parsed)
        if response.success?
          render json: response.value!, status: :ok
        else
          logger.warn "API input error: #{response.failure}"
          render json: { error: 'Invalid parameters' }, status: :bad_request
        end
      rescue JSON::ParserError
        logger.warn "unprocessable json : #{request}"
        render json: { error: 'Bad bot' }, status: :unprocessable_entity
      end
    end
  end
end