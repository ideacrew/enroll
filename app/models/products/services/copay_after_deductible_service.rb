# frozen_string_literal: true

module Products
  module Services
    class CopayAfterDeductibleService < BaseService

      attr_accessor :record

      def initialize(record)
        @record = record
      end

      def in_network_process
        number, _string = record.copay_in_network_tier_1.split(/\ (?=[\w])/)
        if record.co_insurance_in_network_tier_1.include?("Not Applicable")
          "You must meet the deductible first, then #{number} per prescription"
        elsif record.co_insurance_in_network_tier_1.include?("No Charge after deductible")
          if record.qhp_cost_share_variance.medical_and_drug_deductible?
            "You must meet the deductible first, then #{number} per prescription"
          elsif record.qhp_cost_share_variance.separarate_drug_deductible? && DRUG_DEDUCTIBLE_OPTIONS.include?(record.visit_type)
            "You must meet the separate drug deductible first, then #{number} per prescription"
          elsif record.qhp_cost_share_variance.separarate_medical_deductible?
            "You must meet the deductible first, then #{number} per visit."
          end
        elsif record.co_insurance_in_network_tier_1.gsub("%","").to_i == 100 #ticket_42680
          "You must meet the deductible first, then #{number} per visit"
        end
      end

      def out_network_process
        number, _string = record.copay_out_of_network.split(/\ (?=[\w])/)
        if record.co_insurance_out_of_network.gsub("%","").to_i == 100 #ticket_42680
          "You must meet the out-of-network deductible first, then #{number} per visit"
        #WIP
        # elsif NO_CHARGE.include?(record.co_insurance_out_of_network)
        #     NO_CHARGE
        # elsif record.co_insurance_out_of_network.gsub("%","").to_i.zero?
        #   NO_CHARGE
        # elsif record.co_insurance_out_of_network.gsub("%","").to_i == 100
        #   "Not covered. You are responsible for the full cost"
        end
      end
    end
  end
end
