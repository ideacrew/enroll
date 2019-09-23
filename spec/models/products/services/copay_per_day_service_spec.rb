# frozen_string_literal: true

require 'rails_helper'

describe Products::Services::CopayPerDayService do
  let(:amount) { "$300.00" }
  let(:not_applicable) {"Not Applicable"}

  context "In Network Costs" do
    context "$[PARAM] Copay per Day/Not Applicable Coinsurance" do
      let(:service_visit) do
        build(:products_qhp_service_visit, copay_in_network_tier_1: "#{amount} Copay per Day", co_insurance_in_network_tier_1: not_applicable)
      end

      it "should return translated result" do
        expect(Products::Services::CopayPerDayService.new(service_visit).in_network_process).to eq "#{amount} copay per day"
      end
    end

    context "$0 Copay per day/100% Coinsurance" do
      let(:service_visit) do
        build(:products_qhp_service_visit, copay_in_network_tier_1: "$0.00 Copay per Day", co_insurance_in_network_tier_1: "100%")
      end

      it "should return translated result" do
        expect(Products::Services::CopayPerDayService.new(service_visit).in_network_process).to eq "Not covered. You are responsible for the full cost."
      end
    end
  end

  context "Out of Network Costs" do
    context "$0 Copay per day/100% Coinsurance" do
      let(:service_visit) do
        build(:products_qhp_service_visit, copay_out_of_network: "$0.00 Copay per Day", co_insurance_out_of_network: "100%")
      end

      it "should return translated result" do
        expect(Products::Services::CopayPerDayService.new(service_visit).out_network_process).to eq "Not covered. You are responsible for the full cost."
      end
    end
  end
end
