class SamlIdpController < SamlIdp::IdpController

  def idp_authenticate(email, password) # not using params intentionally
    user = User.where(:email => email).first
    user && user.valid_password?(password) ? user : nil
  end
  private :idp_authenticate

  def third_party
    hbx_enrollment = ::HbxEnrollment.by_hbx_id(params[:enrollment_id]).first
    hbx_enrollment.payment_transactions << ::PaymentTransaction.new
    hbx_enrollment.save
    @saml_response = idp_make_saml_response(hbx_enrollment)
    render json: {k: @saml_response}
  end

  def other_service
    @response   = OneLogin::RubySaml::Response.new(params[:SAMLResponse], :allowed_clock_drift => 5.seconds)
    respond_to do |format|
      format.html { render 'insured/plan_shoppings/enrollment_details'}
    end
  end


  def idp_make_saml_response(found_user) # not using params intentionally
    # NOTE encryption is optional
    encode_response found_user,{audience_uri: "localhost:3000", algorithm: SamlIdp.config.algorithm, session_expiry: config.session_expiry,
                                issuer_uri: "fx-ffe-w7-15.cgifederal.com"}
  end
  private :idp_make_saml_response

end
