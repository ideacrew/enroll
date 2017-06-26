
require 'net/http'
require 'uri'

require 'openssl'
require 'base64'

require 'json'

module WellsFargo
  module BillPay
    class SingleSignOn

      API_URL = "https://demo.e-billexpress.com:443/PayIQ/Api/SSO"
      API_KEY = "e2dab122-114a-43a3-aaf5-78caafbbec02"
      COMPANY_NAME = "DCHBX"
      BILLER_KEY = "3741"
      EMAIL = "antonio.schaffert@dc.gov"
      SECRET = "dchbx 2017"
      API_VERSION = "3000"
      PRIVATE_KEY_LOCATION = "/Users/antonioschaffert/workspace/wfpk.pem"

      def initialize(reference_number, external_id)
         @reference_number = reference_number
         @external_id = external_id
      end

      def token

        return @token if defined? @token

        @creation_date = Time.now.strftime("%Y-%m-%dT%H:%M:%S.0000000%z")
        private_key = OpenSSL::PKey::RSA.new(File.read(PRIVATE_KEY_LOCATION))

        message = SECRET + @creation_date

        signature = private_key.sign(OpenSSL::Digest::SHA512.new, message)

        uri = URI.parse(API_URL)
        request = Net::HTTP::Post.new(uri)
        request.set_form_data(
          "APIKey" => API_KEY,
          "ReferenceNumber" => @reference_number,
          "NameCompany" => COMPANY_NAME,
          "APIVersion" => API_VERSION,
          "OtherData" => "Other",
          "Role" => "SSOCustomer",
          "ExternalID" => @external_id,
          "CreationDate" => @creation_date,
          "BillerKey" => BILLER_KEY,
          "Email" => EMAIL,
          "Signature" => Base64.strict_encode64(signature)
        )

        req_options = {
          use_ssl: uri.scheme == "https",
        }

        response = Net::HTTP.start(uri.hostname, uri.port, req_options) do |http|
          http.request(request)
        end

        @response_code = response.code
        @response_body = JSON.parse(response.body)
        @url = @response_body["Url"]
        @token = @response_body["Token"] if @response_code == "200"

      end

      def url
        @url
      end

      def response_body
        @response_body
      end

      def response_code
        @response_code
      end

    end
  end
end
