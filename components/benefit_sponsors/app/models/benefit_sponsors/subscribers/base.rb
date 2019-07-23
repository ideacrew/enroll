module BenefitSponsors
  module Subscribers
    module Base
      def extract_response_params(properties)
        headers = properties.headers || {}
        stringed_headers = headers.stringify_keys
        correlation_id = properties.correlation_id
        workflow_id = stringed_headers["workflow_id"]

        response_params = Hash.new
        if correlation_id.present?
          response_params[:correlation_id] = correlation_id
        end
        if workflow_id.present?
          response_params[:workflow_id] = workflow_id
        end

        response_params
      end

      def extract_workflow_id(properties)
        headers = properties.headers || {}
        stringed_headers = headers.stringify_keys
        stringed_headers["workflow_id"] || SecureRandom.uuid.gsub("-","")
      end
    end
  end
end