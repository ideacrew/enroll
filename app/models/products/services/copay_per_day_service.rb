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
        "#{number} copay per day" if record.co_insurance_in_network_tier_1.include?("Not Applicable") #ticket_42684
      end

    end
  end
end
