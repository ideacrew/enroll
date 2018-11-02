var KpPaymentRedirection = (function(){
    var saml_response;

    // update payload every time when user clicks on PayNow button
    function responseData(data){
        saml_response = data.SAMLResponse;
    }

    // generate payment data
    function generatePaymentData(){
        var element = $('#kp-pay-now');
        var enrollment = element.attr("data-enrollment");
        $.ajax({
            type: "GET",
            url: "/payment_transactions/generate_saml_response",
            data: {enrollment_id: enrollment},
            success: function(data, textStatus, jqXHR){
                // check if data generated
                validateRedirectionRequest(data);
            }
        });
    }

    function validateRedirectionRequest(data){
        if (data.SAMLResponse ) {
            // update payload variable
            responseData(data);
        } else {
            // error message
            var $payNowModal = $('#payNowModal');
            var noPayloadError = document.createElement('div');
            noPayloadError.classList.add('alert', 'alert-danger');
            noPayloadError.innerText = "Error. Payment data can't be generated";
            $payNowModal.modal('hide');
            $payNowModal.siblings().first().prepend(noPayloadError);
        }
    }

    function paymentRedirectionRequest(){
        $('#payNowModal').modal('hide');
        if (saml_response){
            $.ajax({
                type: "POST",
                url: "KP/URI",
                data: {"SAMLResponse": saml_response},
                success: function(data, textStatus, jqXHR){
                    //response handler
                },
                error: function(jqXHR, textStatus, errorThrown){
                    //error handler
                }
            });
        } else {
            generatePaymentData();
        }
    }

    return {
        generate_payment_data: generatePaymentData,
        validate_payload: validateRedirectionRequest,
        payment_redirection_request: paymentRedirectionRequest

    }

})();

$(document).ready(function(){
    // ajax call to genarate transaction record and saml payment data
    $('#kp-pay-now').on('click', KpPaymentRedirection.generate_payment_data);
    // send SAML request and IdP, we act as SP that sends SAML response
    $('#payment-redirect-kp').on('click', KpPaymentRedirection.payment_redirection_request);
});