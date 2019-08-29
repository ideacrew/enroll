# frozen_string_literal: true

module Products
  module Services
    class ZeroCopayService

      attr_accessor :record
      NO_CHARGE = ["No Charge", "Not Applicable"].freeze

      def initialize(record)
        @record = record
      end

      def process
        if NO_CHARGE.include?(record.co_insurance_in_network_tier_1)
          "No Charge"
        elsif record.co_insurance_in_network_tier_1.include?("Coinsurance after deductible")
          number, _string = record.co_insurance_in_network_tier_1.split(/\ (?=[\w])/)
          "You must meet the deductible first, then #{number} of allowed charges"
        elsif record.co_insurance_in_network_tier_1.gsub("%","").to_i.zero?
          "No Charge"
        elsif record.co_insurance_in_network_tier_1.gsub("%","").to_i == 100
          "Not covered. You are responsible for the full cost"
        end
      end
    end
  end
end