# frozen_string_literal: true

module Products
  module Services
    class CopayPerDayService < BaseService

      attr_accessor :record

      def initialize(record)
        @record = record
      end

      def in_network_process
        number, _string = record.copay_in_network_tier_1.split(/\ (?=[\w])/)
        if record.co_insurance_in_network_tier_1.include?("Not Applicable") #ticket_42684
          "#{number} copay per day"
        elsif record.co_insurance_in_network_tier_1.delete("%").to_i == 100 && number.to_i.zero? #ticket_42694
          "Not covered. You are responsible for the full cost."
        end
      end

      def out_network_process
        number, _string = record.copay_out_of_network.split(/\ (?=[\w])/)
        "Not covered. You are responsible for the full cost." if record.co_insurance_out_of_network.delete("%").to_i == 100 && number.to_i.zero? #ticket_42694
      end

    end
  end
end
