module Api
  module V2
    class SlcspCalculatorController < ApiBaseController
      skip_before_action :require_login

      def estimate
        errors = []
        puts params
        if params[:taxYear].blank?
          errors << 'No parameters provided'
        end
        response = []
        for i in 1..12
          response << { month: i, month_name: Date::MONTHNAMES[i] , slcsp: rand(10000..50000).fdiv(100) }
        end
        render json: { error: 'No parameters provided' }, status: :bad_request if errors.present?
        render json: response, status: :ok
      end
    end 
  end 
end  