# frozen_string_literal: true

#generation of saml response for payment transactions
class PaymentTransactionsController < ApplicationController
  skip_before_action :verify_authenticity_token

  include OneLogin::RubySaml

  # TODO: Rename this controller and it's actions.  What's actually happening
  #       here is a set of actions being executed in order to implment PayNow
  #       functionality - we should alter the nomenclature to reflect that.
  def generate_saml_response
    @hbx_enrollment = ::HbxEnrollment.by_hbx_id(params[:enrollment_id]).first
    authorize @hbx_enrollment, :pay_now?
    issuer = issuer_name(params[:enrollment_id])
    status = carrier_connect_test(issuer) if Rails.env.production? #checks to see if EA can connect to carrier payment portal.
    result = Operations::GenerateSamlResponse.new.call({enrollment_id: params[:enrollment_id], source: params[:source]})
    if result.success?
      respond_to do |format|
        format.json { render json: {"SAMLResponse": result.value![:SAMLResponse], status: status, error: nil} }
      end
    else
      respond_to do |format|
        format.json { render json: {error: result.failure} }
      end
    end
  rescue StandardError => e
    respond_to do |format|
      format.json { render json: {error: e} }
    end
  end

  private

  def carrier_connect_test(issuer)
    key = "#{issuer}_pay_now".to_sym
    EnrollRegistry[key].setting(:connect_test).item ? HTTParty.post(SamlInformation.send("#{issuer}_pay_now_url")).code : 200
  end

  def issuer_name(enr_id)
    enrollment = HbxEnrollment.by_hbx_id(enr_id).last if enr_id.present?
    return unless enrollment.present?
    enrollment.product.issuer_profile.legal_name.downcase.gsub(' ', '_').gsub(/[,.]/, '')
  end
end
