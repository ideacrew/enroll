# frozen_string_literal: true

require 'rails_helper'

describe Products::Services::ZeroCopayService do
  let(:zero_dollar) { "$0.00" }
  let(:no_charge) {"No Charge"}

  context "In Network Costs" do
    context "zero copay and zero coinsurance" do
      let(:service_visit) do
        build(:products_qhp_service_visit, copay_in_network_tier_1: zero_dollar, co_insurance_in_network_tier_1: zero_dollar)
      end

      it "should return translated result" do
        expect(Products::Services::ZeroCopayService.new(service_visit).in_network_process).to eq Products::Services::BaseService::NO_CHARGE
      end
    end

    context "zero copay and No Charge Coinsurance" do
      let(:service_visit) do
        build(:products_qhp_service_visit, copay_in_network_tier_1: zero_dollar, co_insurance_in_network_tier_1: no_charge)
      end

      it "should return translated result" do
        expect(Products::Services::ZeroCopayService.new(service_visit).in_network_process).to eq Products::Services::BaseService::NO_CHARGE
      end
    end

    context "zero copay and [PARAM]% Coinsurance after deductible" do
      let(:percentage) {"20%"}
      let(:service_visit) do
        build(:products_qhp_service_visit, copay_in_network_tier_1: zero_dollar, co_insurance_in_network_tier_1: "#{percentage} Coinsurance after deductible", visit_type: "Dental Check-Up for Children")
      end

      it "should return translated result" do
        expect(Products::Services::ZeroCopayService.new(service_visit).in_network_process).to eq "You must meet the deductible first, then #{percentage} of allowed charges"
      end
    end

    context "zero copay and 100% coinsurance" do
      let(:service_visit) do
        build(:products_qhp_service_visit, copay_in_network_tier_1: zero_dollar, co_insurance_in_network_tier_1: "100%")
      end

      it "should return translated result" do
        expect(Products::Services::ZeroCopayService.new(service_visit).in_network_process).to eq "Not covered. You are responsible for the full cost"
      end
    end
  end


  context "Out of Network Costs" do
    context "zero copay and [PARAM]% Coinsurance after deductible" do
      let(:percentage) {"20%"}
      let(:service_visit) do
        build(:products_qhp_service_visit, copay_out_of_network: zero_dollar, co_insurance_out_of_network: "#{percentage} Coinsurance after deductible", visit_type: "Durable Medical Equipment" )
      end

      it "should return translated result" do
        expect(Products::Services::ZeroCopayService.new(service_visit).out_network_process).to eq "You must meet the out-of-network deductible first, then #{percentage} of allowed charges per device."
      end
    end
  end
end
