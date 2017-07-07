module NfpIntegration
  module SoapServices
    class NfpAuthenticateUser

      SOAP_ACTION = "http://www.nfp.com/schemas/hbcore/IPremiumBillingIntegrationServices/AuthenticateUser"

      SOAP_BODY = <<-XMLCODE
      <soapenv:Envelope xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/" xmlns:hbc="http://www.nfp.com/schemas/hbcore">
         <soapenv:Header/>
         <soapenv:Body>
            <hbc:AuthenticationReq>
               <!--Optional:-->
               <hbc:UserName>%{user}</hbc:UserName>
               <!--Optional:-->
               <hbc:Password>%{password}</hbc:Password>
            </hbc:AuthenticationReq>
         </soapenv:Body>
      </soapenv:Envelope>
      XMLCODE

      def initialize
        SOAP_BODY.freeze
      end

      def body
        SOAP_BODY
      end

      def soap_action
        SOAP_ACTION
      end

    end
  end
end
