
require 'net/http'
require 'uri'

require 'openssl'
require 'base64'

require 'json'

module WellsFargo
  module BillPay
    class SingleSignOn


      #TODO Move this to config/init files
      API_URL = "https://demo.e-billexpress.com:443/PayIQ/Api/SSO"
      API_KEY = "e2dab122-114a-43a3-aaf5-78caafbbec02"
      BILLER_KEY = "3741"
      SECRET = "dchbx 2017"
      API_VERSION = "3000"
      PRIVATE_KEY_LOCATION = "/wfpk.pem" #TEMP
      DATE_FORMAT = "%Y-%m-%dT%H:%M:%S.0000000%z"

      def initialize(reference_number, external_id, company_name, email)
         @reference_number = reference_number
         @external_id = external_id
         @company_name = company_name
         @email = email
      end

      def token

        return @token if defined? @token

        begin

          @creation_date = Time.now.strftime(DATE_FORMAT)
          private_key = OpenSSL::PKey::RSA.new(File.read(Rails.root.join('config','ssl').to_s + PRIVATE_KEY_LOCATION))

          message = SECRET + @creation_date

          signature = private_key.sign(OpenSSL::Digest::SHA512.new, message)

          uri = URI.parse(API_URL)
          request = Net::HTTP::Post.new(uri)
          request.set_form_data(
            "APIKey" => API_KEY,
            "ReferenceNumber" => @reference_number,
            "NameCompany" => @company_name,
            "APIVersion" => API_VERSION,
            "OtherData" => @reference_number,
            "Role" => "SSOCustomer",
            "ExternalID" => @external_id,
            "CreationDate" => @creation_date,
            "BillerKey" => BILLER_KEY,
            "Email" => @email,
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

        rescue => e
          Rails.logger.error "WellsFargo SingleSignOn error: #{e.message}"
          @response_code = nil
          @response_body = nil
          @url = nil
          @token = nil
        end

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
