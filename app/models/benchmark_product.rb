# frozen_string_literal: true

# This class is to persist all calculations made by Operations::BenchmarkProducts::IdentifySlcspWithPediatricDentalCosts.
# This class persists both request_payload and response_payload in JSON format.
class BenchmarkProduct
  include Mongoid::Document
  include Mongoid::Timestamps

  field :family_id, type: BSON::ObjectId

  # Request Payload that is sent to Operations::BenchmarkProducts::IdentifySlcspWithPediatricDentalCosts in JSON format
  field :request_payload, type: String

  # Response Payload that is sent back from Operations::BenchmarkProducts::IdentifySlcspWithPediatricDentalCosts in JSON format
  # This response payload includes all the calculations
  field :response_payload, type: String

  def request
    JSON.parse(request_payload, symbolize_names: true)
  end

  def response
    JSON.parse(response_payload, symbolize_names: true)
  end
end
