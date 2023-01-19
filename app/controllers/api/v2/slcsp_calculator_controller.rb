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
        values = []
        for i in 1..12
          values << { month: i, month_name: Date::MONTHNAMES[i] , slcsp: rand(10000..50000).fdiv(100) }
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