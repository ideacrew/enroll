module NfpIntegration
  module SoapServices
    class NfpPaymentHistory

      SOAP_ACTION = "http://www.nfp.com/schemas/hbcore/IPremiumBillingIntegrationServices/GetCustomersPaymentHistory"

      SOAP_BODY = <<-XMLCODE
<soapenv:Envelope xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/" xmlns:hbc="http://www.nfp.com/schemas/hbcore">
 <soapenv:Header>
    <hbc:AuthToken>%{token}</hbc:AuthToken>
 </soapenv:Header>
 <soapenv:Body>
    <hbc:PaymentHistoryReq>
       <hbc:CustomerCode>%{customer_id}</hbc:CustomerCode>
    </hbc:PaymentHistoryReq>
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
