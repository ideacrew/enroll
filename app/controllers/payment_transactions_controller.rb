class PaymentTransactionsController < ApplicationController
  skip_before_action :verify_authenticity_token

  include OneLogin::RubySaml

  def generate_saml_response
    connect_test = HTTParty.post(SamlInformation.kp_pay_now_url) #checks to see if EA can connect to carrier payment portal.
    status = connect_test.code if Rails.env.production?
    result = Operations::GenerateSamlResponse.new.call({enrollment_id: params[:enrollment_id], source: params[:source]})
    if result.success?
      render json: {"SAMLResponse": result.value![:SAMLResponse], status: status, error: nil}
    else
      render json: {error: result.failure}
    end
  rescue StandardError => e
    render json: {error: e}
  end
end