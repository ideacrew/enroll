# frozen_string_literal: true

require 'rails_helper'

describe Products::Services::CopayAfterDeductibleService do
  let(:amount) { "$75" }
  let(:percentage) {"100%"}

  context "In Network Costs" do
    context "$[PARAM] Copay after deductible/100% Coinsurance" do
      let(:service_visit) do
        build(:products_qhp_service_visit, copay_in_network_tier_1: "#{amount} copay after deductible", co_insurance_in_network_tier_1: percentage)
      end

      it "should return translated result" do
        expect(Products::Services::CopayAfterDeductibleService.new(service_visit).in_network_process).to eq "You must meet the deductible first, then #{amount} per visit"
      end
    end

    context "$[PARAM] Copay after deductible/No Charge after deductible Coinsurance" do
      let(:qhp_cost_share_variance) { instance_double(Products::QhpCostShareVariance, :qhp_service_visits => [service_visit]) }
      let(:service_visit) do
        build(:products_qhp_service_visit, copay_in_network_tier_1: "#{amount} copay after deductible", co_insurance_in_network_tier_1: "No Charge after deductible")
      end

      context "with Drug costs And Combined Plan (medical and dental deductible)" do
        before do
          allow(service_visit).to receive(:qhp_cost_share_variance).and_return(qhp_cost_share_variance)
          allow(qhp_cost_share_variance).to receive(:medical_and_drug_deductible?).and_return true
          allow(qhp_cost_share_variance).to receive(:separarate_drug_deductible?).and_return false
          allow(qhp_cost_share_variance).to receive(:separarate_medical_deductible?).and_return false
        end

        it "should return translated result" do
          expect(Products::Services::CopayAfterDeductibleService.new(service_visit).in_network_process).to eq "You must meet the deductible first, then #{amount} per prescription"
        end
      end

      context "with Drug costs And separate drug deductible" do
        let(:service_visit) do
          build(:products_qhp_service_visit, copay_in_network_tier_1: "#{amount} copay after deductible", co_insurance_in_network_tier_1: "No Charge after deductible", visit_type: "Separate Drug Deductible")
        end

        before do
          allow(service_visit).to receive(:qhp_cost_share_variance).and_return(qhp_cost_share_variance)
          allow(qhp_cost_share_variance).to receive(:separarate_drug_deductible?).and_return true
          allow(qhp_cost_share_variance).to receive(:medical_and_drug_deductible?).and_return false
          allow(qhp_cost_share_variance).to receive(:separarate_medical_deductible?).and_return false
        end

        it "should return translated result" do
          expect(Products::Services::CopayAfterDeductibleService.new(service_visit).in_network_process).to eq "You must meet the separate drug deductible first, then #{amount} per prescription."
        end
      end

      context "for remaining services" do

        before do
          allow(service_visit).to receive(:qhp_cost_share_variance).and_return(qhp_cost_share_variance)
          allow(qhp_cost_share_variance).to receive(:separarate_drug_deductible?).and_return false
          allow(qhp_cost_share_variance).to receive(:medical_and_drug_deductible?).and_return false
          allow(qhp_cost_share_variance).to receive(:separarate_medical_deductible?).and_return true
        end

        it "should return translated result" do
          expect(Products::Services::CopayAfterDeductibleService.new(service_visit).in_network_process).to eq "You must meet the deductible first, then #{amount} per visit"
        end
      end

    end
  end


  context "Out of Network Costs" do
    context "$[PARAM] Copay after deductible/100% Coinsurance" do
      let(:service_visit) do
        build(:products_qhp_service_visit, copay_out_of_network: "#{amount} copay after deductible", co_insurance_out_of_network: percentage)
      end

      it "should return translated result" do
        expect(Products::Services::CopayAfterDeductibleService.new(service_visit).out_network_process).to eq "You must meet the out-of-network deductible first, then #{amount} per visit"
      end
    end
  end
end
