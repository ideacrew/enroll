# frozen_string_literal: true

require 'rails_helper'

describe Products::Services::CopayAfterDeductibleService do
  let(:amount) { "$75" }
  let(:percentage) {"100%"}

  context "In Network Costs" do
    context "zero copay and zero coinsurance" do
      let(:service_visit) do
        build(:products_qhp_service_visit, copay_in_network_tier_1: "#{amount} copay after deductible", co_insurance_in_network_tier_1: percentage)
      end

      it "should return translated result" do
        expect(Products::Services::CopayAfterDeductibleService.new(service_visit).in_network_process).to eq "You must meet the deductible first, then #{amount} per visit"
      end
    end
  end


  context "Out of Network Costs" do
    context "zero copay and [PARAM]% Coinsurance after deductible" do
      let(:service_visit) do
        build(:products_qhp_service_visit, copay_out_of_network: "#{amount} copay after deductible", co_insurance_out_of_network: percentage)
      end

      it "should return translated result" do
        expect(Products::Services::CopayAfterDeductibleService.new(service_visit).out_network_process).to eq "You must meet the out-of-network deductible first, then #{amount} per visit"
      end
    end
  end
end
