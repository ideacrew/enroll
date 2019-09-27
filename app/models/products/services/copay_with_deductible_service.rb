# frozen_string_literal: true

module Products
  module Services
    class CopayWithDeductibleService < BaseService

      attr_accessor :record

      def initialize(record)
        @record = record
      end

      def in_network_process
        number, _string = record.copay_in_network_tier_1.split(/\ (?=[\w])/)
        return unless record.co_insurance_in_network_tier_1.include?("No Charge after deductible") #ticket_42691
        return unless DRUG_DEDUCTIBLE_OPTIONS.exclude?(record.visit_type) #ticket_42691
        if record.qhp_cost_share_variance.no_in_network_deductible? #ticket_42691
          if DEVICES.include?(record.visit_type)
            "You must pay #{number} per device."
          elsif EXPECTED_SERVICES.include?(record.visit_type)
            "You must pay #{number} per visit."
          end
        elsif DEVICES.include?(record.visit_type)
          "You must first pay #{number} per device. Then, pay all of the remaining allowed charges, until you meet the deductible. After you meet the deductible, no charge."
        else
          "You must first pay #{number} per visit. Then, pay all of the remaining allowed charges, until you meet the deductible. After you meet the deductible, no charge"
        end
      end

      def out_network_process
        number, _string = record.copay_out_of_network.split(/\ (?=[\w])/)
        return unless record.co_insurance_out_of_network.include?("No Charge after deductible")
        return unless DRUG_DEDUCTIBLE_OPTIONS.exclude?(record.visit_type) #ticket_42691
        if record.qhp_cost_share_variance.no_out_of_network_deductible?
          if EXPECTED_SERVICES.include?(record.visit_type) #ticket_42691
            "You must first pay #{number} per visit. Then, pay all of the remaining allowed charges, until you meet the deductible. After you meet the deductible, no charge."
          elsif DEVICES.include?(record.visit_type) #ticket_42691
            "You must first pay #{number} per device. Then, pay all of the remaining allowed charges, until you meet the deductible. After you meet the deductible, no charge."
          end
        elsif DEVICES.include?(record.visit_type)
          "You must first pay #{number} per device. Then, pay all of the remaining allowed charges, until you meet the out-of-network deductible. After you meet the deductible, no charge."
        else #ticket_42691
          "You must first pay #{number} per visit. Then, pay all of the remaining allowed charges, until you meet the out-of-network deductible. After you meet the deductible, no charge."
        end
      end

    end
  end
end
