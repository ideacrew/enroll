# frozen_string_literal: true

require 'net/http'
require 'uri'
require 'openssl'
require 'base64'
require 'json'

module WellsFargo
  module BillPay
    class SingleSignOn

      API_URL = Rails.application.config.wells_fargo_api_url
      API_KEY = Rails.application.config.wells_fargo_api_key
      BILLER_KEY = Rails.application.config.wells_fargo_biller_key
      SECRET = Rails.application.config.wells_fargo_api_secret
      API_VERSION = Rails.application.config.wells_fargo_api_version
      PRIVATE_KEY_LOCATION = Rails.application.config.wells_fargo_private_key_location
      DATE_FORMAT = Rails.application.config.wells_fargo_api_date_format

      attr_reader :url, :response_body, :response_code

      def initialize(reference_number, external_id, company_name, email)
        @reference_number = reference_number
        @external_id = external_id
        @company_name = company_name
        @email = email
      end

      def token
        return @token if defined? @token

        begin
          @creation_date = Time.zone.now.strftime(DATE_FORMAT)
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
            use_ssl: uri.scheme == "https"
          }

          response = Net::HTTP.start(uri.hostname, uri.port, req_options) do |http|
            http.request(request)
          end

          @response_code = response.code
          @response_body = JSON.parse(response.body)
          @url = @response_body["Url"]
          @token = @response_body["Token"] if @response_code == "200"
        rescue StandardError => e
          Rails.logger.error "WellsFargo SingleSignOn error: #{e.message}"
          @response_code = nil
          @response_body = nil
          @url = nil
          @token = nil
        end
      end
    end
  end
end
