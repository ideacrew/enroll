# frozen_string_literal: true

module Products
  module Services
    class CopayPerStayService < BaseService

      attr_accessor :record

      def initialize(record)
        @record = record
      end

      def in_network_process
        number, _string = record.copay_in_network_tier_1.split(/\ (?=[\w])/)
        if record.co_insurance_in_network_tier_1.include?("Not Applicable") #ticket_42686
          "#{number} copay per stay"
        elsif record.co_insurance_in_network_tier_1.delete("%").to_i == 100 && record.copay_in_network_tier_1.include?("after deductible") #ticket_42687
          "You must first meet the deductible, then #{number} per stay."
        end
      end

      def out_network_process
        number, _string = record.copay_out_of_network.split(/\ (?=[\w])/)
        "You must first meet the out-of-network deductible, then #{number} per stay." if record.co_insurance_out_of_network.delete("%").to_i == 100 && record.copay_out_of_network.include?("after deductible") #ticket_42694
      end

    end
  end
end
