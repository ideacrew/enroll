require 'net/http'
require 'uri'
require 'pry'
require 'nokogiri'

module NfpIntegration
  module SoapServices
    class Nfp

      # Change below to Pre Prod
      NFP_URL = "http://localhost:9000/cpbservices/PremiumBillingIntegrationServices.svc"
      NFP_USER_ID = "testuser" #TEST ONLY
      NFP_PASS = "M0rph!us007" #TEST ONLY

      def initialize(customer_id)
        @customer_id = customer_id
        token
      end

      def  customer_pdf_statement

        return nil if @token.blank?

        uri = URI.parse(NFP_URL)
        request = Net::HTTP::Post.new(uri)
        request.content_type = "text/xml;charset=UTF-8"
        request["Soapaction"] = "http://www.nfp.com/schemas/hbcore/IPremiumBillingIntegrationServices/GetStatementPDFForCustomer"
        request.body = ""
        request.body = <<-XMLCODE
<soapenv:Envelope xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/" xmlns:hbc="http://www.nfp.com/schemas/hbcore">
   <soapenv:Header>
      <hbc:AuthToken>#{@token}</hbc:AuthToken>
   </soapenv:Header>
   <soapenv:Body>
      <hbc:StatementPdfReq>
         <hbc:CustomerCode>#{@customer_id}</hbc:CustomerCode>
      </hbc:StatementPdfReq>
   </soapenv:Body>
</soapenv:Envelope>
XMLCODE

        req_options = {
          use_ssl: uri.scheme == "https",
        }

        response = Net::HTTP.start(uri.hostname, uri.port, req_options) do |http|
            http.request(request)
        end


        if response.code == "200"
          doc = Nokogiri::XML(response.body)
          return doc.remove_namespaces!
        end

        return response.code

      end

      def payment_history

        return nil if @token.blank?

        uri = URI.parse(NFP_URL)
        request = Net::HTTP::Post.new(uri)
        request.content_type = "text/xml;charset=UTF-8"
        request["Soapaction"] = "http://www.nfp.com/schemas/hbcore/IPremiumBillingIntegrationServices/GetCustomersPaymentHistory"
        request.body = ""
        request.body = <<-XMLCODE
<soapenv:Envelope xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/" xmlns:hbc="http://www.nfp.com/schemas/hbcore">
   <soapenv:Header>
      <hbc:AuthToken>#{@token}</hbc:AuthToken>
   </soapenv:Header>
   <soapenv:Body>
      <hbc:PaymentHistoryReq>
         <hbc:CustomerCode>#{@customer_id}</hbc:CustomerCode>
      </hbc:PaymentHistoryReq>
   </soapenv:Body>
</soapenv:Envelope>
XMLCODE

        req_options = {
          use_ssl: uri.scheme == "https",
        }

        response = Net::HTTP.start(uri.hostname, uri.port, req_options) do |http|
            http.request(request)
        end


        if response.code == "200"
          doc = Nokogiri::XML(response.body)
          return doc.remove_namespaces!
        end
        return response.code
      end


      def statement_summary

        return nil if @token.blank?

        uri = URI.parse(NFP_URL)
        request = Net::HTTP::Post.new(uri)
        request.content_type = "text/xml;charset=UTF-8"
        request["Soapaction"] = "http://www.nfp.com/schemas/hbcore/IPremiumBillingIntegrationServices/GetCustomerStatementSummary"
        request.body = ""
        request.body = <<-XMLCODE
<soapenv:Envelope xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/" xmlns:hbc="http://www.nfp.com/schemas/hbcore">
   <soapenv:Header>
      <hbc:AuthToken>#{@token}</hbc:AuthToken>
   </soapenv:Header>
   <soapenv:Body>
      <hbc:StatementSummaryReq>
         <hbc:CustomerCode>#{@customer_id}</hbc:CustomerCode>
      </hbc:StatementSummaryReq>
   </soapenv:Body>
</soapenv:Envelope>
XMLCODE

        req_options = {
          use_ssl: uri.scheme == "https",
        }

        response = Net::HTTP.start(uri.hostname, uri.port, req_options) do |http|
            http.request(request)
        end


        if response.code == "200"
          doc = Nokogiri::XML(response.body)
          return doc.remove_namespaces!
        end
        return response.code
      end

      def  enrollment_data

        return nil if @token.blank?

        uri = URI.parse(NFP_URL)
        request = Net::HTTP::Post.new(uri)
        request.content_type = "text/xml;charset=UTF-8"
        request["Soapaction"] = "http://www.nfp.com/schemas/hbcore/IPremiumBillingIntegrationServices/GetCustomerEnrollmentData"
        request.body = ""
        request.body = <<-XMLCODE
<soapenv:Envelope xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/" xmlns:hbc="http://www.nfp.com/schemas/hbcore">
   <soapenv:Header>
      <hbc:AuthToken>#{@token}</hbc:AuthToken>
   </soapenv:Header>
   <soapenv:Body>
      <hbc:EnrollmentDataReq>
         <!--Optional:-->
         <hbc:CustomerCode>#{@customer_id}</hbc:CustomerCode>
         <!--Optional:-->
         <hbc:EnrollmentType>CurrentOnly</hbc:EnrollmentType>
      </hbc:EnrollmentDataReq>
   </soapenv:Body>
</soapenv:Envelope>
XMLCODE

        req_options = {
          use_ssl: uri.scheme == "https",
        }

        response = Net::HTTP.start(uri.hostname, uri.port, req_options) do |http|
            http.request(request)
        end


        if response.code == "200"
          doc = Nokogiri::XML(response.body)
          return doc.remove_namespaces!
        end

        return response.code

      end

      def display_token
        @token
      end

      private
        def token

          return @token if defined? @token

          uri = URI.parse(NFP_URL)
          request = Net::HTTP::Post.new(uri)
          request.content_type = "text/xml;charset=UTF-8"
          request["Soapaction"] = "http://www.nfp.com/schemas/hbcore/IPremiumBillingIntegrationServices/AuthenticateUser"
          request.body = ""
          request.body = <<-XMLCODE
<?xml version="1.0" encoding="utf-8"?>
<SOAP-ENV:Envelope xmlns:SOAP-ENV="http://schemas.xmlsoap.org/soap/envelope/" xmlns:SOAP-ENC="http://schemas.xmlsoap.org/soap/encoding/" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema">
      <SOAP-ENV:Body>
              <m:AuthenticationReq xmlns:m="http://www.nfp.com/schemas/hbcore">
                      <m:UserName>#{NFP_USER_ID}</m:UserName>
                      <m:Password>#{NFP_PASS}</m:Password>
                      <m:SubscriptionId>NFP will allocate to DC</m:SubscriptionId>
                      <m:CertThumbprint>For future scope</m:CertThumbprint>
                      <m:ExchangeId>NFP will allocate to DC</m:ExchangeId>
              </m:AuthenticationReq>
      </SOAP-ENV:Body>
</SOAP-ENV:Envelope>
XMLCODE

  puts request.body


          req_options = {
            use_ssl: uri.scheme == "https",
          }

          response = Net::HTTP.start(uri.hostname, uri.port, req_options) do |http|
            http.request(request)
          end

          puts response.code
          puts response.body

          doc = Nokogiri::XML(response.body)
          doc.remove_namespaces!

          puts doc.xpath("//AuthToken").text
          @token = doc.xpath("//AuthToken").text

        end
    end
  end
end
