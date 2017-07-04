require 'net/http'
require 'uri'
require 'nokogiri'

module NfpIntegration
  module SoapServices
    class Nfp

      include NfpIntegration::SoapServices::Base

      # # Change below to Pre Prod 10.0.3.51
      # NFP_URL = "http://localhost:9000/cpbservices/PremiumBillingIntegrationServices.svc"
      # NFP_USER_ID = "testuser" #TEST ONLY
      # NFP_PASS = "M0rph!us007" #TEST ONLY

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

        response = Net::HTTP.start(uri.hostname, uri.port, req_options(uri)) do |http|
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

        uri, request = build_request(NfpPaymentHistory.new, {:token => token, :customer_id => @customer_id})

        response = Net::HTTP.start(uri.hostname, uri.port, request_options(uri)) do |http|
          http.request(request)
        end

        if response.code == "200"
          doc = Nokogiri::XML(response.body)
          return doc.remove_namespaces!
        end
        return nil
      end


      def statement_summary

        return nil if @token.blank?

        uri, request = build_request(NfpStatementSummary.new, {:token => token, :customer_id => @customer_id})

        response = Net::HTTP.start(uri.hostname, uri.port, request_options(uri)) do |http|
          http.request(request)
        end

        if response.code == "200"
          doc = Nokogiri::XML(response.body)
          return doc.remove_namespaces!
        end
        return nil
      end

      def  enrollment_data

        return nil if @token.blank?

        uri, request = build_request(NfpEnrollmentData.new, {:token => token, :customer_id => @customer_id})

        response = Net::HTTP.start(uri.hostname, uri.port, request_options(uri)) do |http|
            http.request(request)
        end


        if response.code == "200"
          doc = Nokogiri::XML(response.body)
          return doc.remove_namespaces!
        end

        return nil

      end

      def display_token
        @token.present? ? @token : nil
      end

      # Gets token info from NFP Server
      def get_token_info(token)

        uri, request = build_request(NfpGetTokenInfo.new, {:token => token})

        response = Net::HTTP.start(uri.hostname, uri.port, request_options(uri)) do |http|
          http.request(request)
        end

        puts response.code
        puts response.body

      end

      private

        def build_request(soap_object, parms = {})

          uri = URI.parse(NFP_URL)
          request = Net::HTTP::Post.new(uri)
          request.content_type = "text/xml;charset=UTF-8"
          request["Soapaction"] = soap_object.soap_action
          request.body = soap_object.body % parms


          return uri, request

        end

        def request_options(uri)
          {
            use_ssl: uri.scheme == "https",
          }
        end

        def token

          return @token if defined? @token

          return nil if NFP_PASS == nil || NFP_USER_ID == nil

          uri, request = build_request(NfpAuthenticateUser.new, {:user => NFP_USER_ID, :password => NFP_PASS})

          response = Net::HTTP.start(uri.hostname, uri.port, request_options(uri)) do |http|
            http.request(request)
          end

          puts response.code
          puts response.body

          doc = Nokogiri::XML(response.body)
          doc.remove_namespaces!

          puts get_element_text(doc.xpath("//AuthToken"))
          @token_status = get_element_text(doc.xpath("//Success")) == "true" ? true : false
          @token = get_element_text(doc.xpath("//AuthToken"))

        end
    end
  end
end
