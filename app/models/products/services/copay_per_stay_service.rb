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
        "#{number} copay per stay" if record.co_insurance_in_network_tier_1.include?("Not Applicable") #ticket_42686
      end

    end
  end
end
