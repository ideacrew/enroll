# frozen_string_literal: true

require 'rails_helper'

describe Products::Services::CopayPerStayService do
  let(:amount) { "$300.00" }
  let(:not_applicable) {"Not Applicable"}

  context "In Network Costs" do
    context "$[PARAM] Copay per Stay/Not Applicable Coinsurance" do
      let(:service_visit) do
        build(:products_qhp_service_visit, copay_in_network_tier_1: "#{amount} Copay per Stay", co_insurance_in_network_tier_1: not_applicable)
      end

      it "should return translated result" do
        expect(Products::Services::CopayPerStayService.new(service_visit).in_network_process).to eq "#{amount} copay per stay"
      end
    end

    context "$[PARAM] Copay per Stay after deductible/100% Coinsurance" do
      let(:service_visit) do
        build(:products_qhp_service_visit, copay_in_network_tier_1: "#{amount} Copay per Stay after deductible", co_insurance_in_network_tier_1: "100%")
      end

      it "should return translated result" do
        expect(Products::Services::CopayPerStayService.new(service_visit).in_network_process).to eq "You must meet the deductible first, then #{amount} per stay."
      end
    end

    context "$[PARAM] Copay per Stay after deductible/Not Applicable Coinsurance" do
      let(:service_visit) do
        build(:products_qhp_service_visit, copay_in_network_tier_1: "#{amount} Copay per Stay after deductible", co_insurance_in_network_tier_1: not_applicable)
      end

      it "should return translated result" do
        expect(Products::Services::CopayPerStayService.new(service_visit).in_network_process).to eq "You must meet the deductible first, then #{amount} per stay."
      end
    end

    context "$[PARAM] Copay per Stay with deductible/Not Applicable Coinsurance" do
      let(:service_visit) do
        build(:products_qhp_service_visit, copay_in_network_tier_1: "#{amount} Copay per Stay with deductible", co_insurance_in_network_tier_1: not_applicable)
      end
      let(:result) {"You pay #{amount} copay per stay. You are also responsible for any remaining allowed charges, which will accrue towards your yearly deductible."}

      it "should return translated result" do
        expect(Products::Services::CopayPerStayService.new(service_visit).in_network_process).to eq result
      end
    end
  end

  context "Out of Network Costs" do
    context "$[PARAM] Copay per Stay after deductible/100% Coinsurance" do
      let(:service_visit) do
        build(:products_qhp_service_visit, copay_out_of_network: "#{amount} Copay per Stay after deductible", co_insurance_out_of_network: "100%")
      end

      it "should return translated result" do
        expect(Products::Services::CopayPerStayService.new(service_visit).out_network_process).to eq "You must first meet the out-of-network deductible, then #{amount} per stay."
      end
    end

    context "$[PARAM] Copay per Stay after deductible/Not Applicable Coinsurance" do
      let(:service_visit) do
        build(:products_qhp_service_visit, copay_out_of_network: "#{amount} Copay per Stay after deductible", co_insurance_out_of_network: not_applicable)
      end

      it "should return translated result" do
        expect(Products::Services::CopayPerStayService.new(service_visit).out_network_process).to eq "You must first meet the out-of-network deductible, then #{amount} per stay."
      end
    end

    context "$[PARAM] Copay per Stay with deductible/Not Applicable Coinsurance" do
      let(:service_visit) do
        build(:products_qhp_service_visit, copay_out_of_network: "#{amount} Copay per Stay with deductible", co_insurance_out_of_network: not_applicable)
      end
      let(:result) {"You pay #{amount} copay per stay. You are also responsible for any remaining allowed charges, which will accrue towards your yearly out-of-network deductible."}

      it "should return translated result" do
        expect(Products::Services::CopayPerStayService.new(service_visit).out_network_process).to eq result
      end
    end
  end
end
