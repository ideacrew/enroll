module NfpIntegration
  module SoapServices
    class NfpPdfStatement

      SOAP_ACTION = "http://www.nfp.com/schemas/hbcore/IPremiumBillingIntegrationServices/GetStatementPDFForCustomer"

      SOAP_BODY = <<-XMLCODE
<soapenv:Envelope xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/" xmlns:hbc="http://www.nfp.com/schemas/hbcore">
   <soapenv:Header>
      <hbc:AuthToken>%{token}</hbc:AuthToken>
   </soapenv:Header>
   <soapenv:Body>
      <hbc:StatementPdfReq>
         <!--Optional:-->
         <hbc:RequestArgs>
            <!--Optional:-->
            <hbc:CustomerCode>%{customer_id}</hbc:CustomerCode>
            <!--Optional:-->
            <hbc:NoOfStatements>1</hbc:NoOfStatements>
         </hbc:RequestArgs>
      </hbc:StatementPdfReq>
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
