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

  end
end
