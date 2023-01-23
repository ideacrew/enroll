# frozen_string_literal: true

module Api
  module V2
    # This class handles the SLCSP Calculator API, this returns an estimate of payments for premiums for the year requested
    class SlcspCalculatorController < ApiBaseController
      skip_before_action :require_login

      def estimate
        errors = []
        errors << 'No parameters provided' if params[:taxYear].blank?
        values = []
        (1..12).each do |i|
          values << { month: i, month_name: Date::MONTHNAMES[i], slcsp: rand(10_000..50_000).fdiv(100) }
        end
        response = { assistance_year: params[:taxYear], values: values }
        if errors.present?
          render json: { error: 'Inavlid parameters' }, status: :bad_request
        else
          render json: response, status: :ok
        end
      end
    end
  end
end