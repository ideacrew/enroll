# frozen_string_literal: true

require 'rails_helper'

describe Products::Services::CopayAfterDeductibleService do
  let(:subject) { Products::Services::CopayWithDeductibleService.new(service_visit) }
  let(:amount) { "$75" }
  let(:percentage) {"100%"}
  let(:qhp_cost_share_variance) { build(:products_qhp_cost_share_variance, :qhp_service_visits => [service_visit]) }
  let(:service_visit) { build(:products_qhp_service_visit) }

  before do
    allow(service_visit).to receive(:qhp_cost_share_variance).and_return(qhp_cost_share_variance)
  end

  context "In Network Costs" do
    context "$[PARAM] Copay after deductible/No Charge after deductible Coinsurance" do
      context "with Medical Costs And NOT have an In Network Deductible and ‘excepted service’" do
        before do
          allow(qhp_cost_share_variance).to receive(:no_in_network_deductible?).and_return true
        end

        it "should return translated result" do
          service_visit.copay_in_network_tier_1 = "#{amount} copay after deductible"
          service_visit.co_insurance_in_network_tier_1 = "No Charge after deductible"
          service_visit.visit_type = "Emergency Room Services"
          expect(subject.in_network_process).to eq "You must pay #{amount} per visit."
        end
      end

      context "with Medical Costs And NOT have an In Network Deductible and have devices" do
        before do
          allow(qhp_cost_share_variance).to receive(:no_in_network_deductible?).and_return true
        end

        it "should return translated result" do
          service_visit.copay_in_network_tier_1 = "#{amount} copay after deductible"
          service_visit.co_insurance_in_network_tier_1 = "No Charge after deductible"
          service_visit.visit_type = "Prosthetic Devices"
          expect(subject.in_network_process).to eq "You must pay #{amount} per device."
        end
      end

      context "with Medical Costs And NOT have an In Network Deductible and have devices" do
        before do
          allow(qhp_cost_share_variance).to receive(:no_in_network_deductible?).and_return false
        end

        it "should return translated result" do
          service_visit.copay_in_network_tier_1 = "#{amount} copay after deductible"
          service_visit.co_insurance_in_network_tier_1 = "No Charge after deductible"
          service_visit.visit_type = "Prosthetic Devices"
          expect(subject.in_network_process).to eq "You must first pay #{amount} per device. Then, pay all of the remaining allowed charges, until you meet the deductible. After you meet the deductible, no charge."
        end
      end

      context "for remaining services" do
        before do
          allow(qhp_cost_share_variance).to receive(:no_in_network_deductible?).and_return false
        end

        it "should return translated result" do
          service_visit.copay_in_network_tier_1 = "#{amount} copay after deductible"
          service_visit.co_insurance_in_network_tier_1 = "No Charge after deductible"
          expect(subject.in_network_process).to eq "You must first pay #{amount} per visit. Then, pay all of the remaining allowed charges, until you meet the deductible. After you meet the deductible, no charge"
        end
      end
    end
  end
end
